import Foundation
import Observation
import ForestCore

/// 앱 상태. 끊는 것에 관한 정보는 전부 이 기기의 파일에만 저장한다.
@MainActor
@Observable
final class AppModel {
    struct SavedState: Codable {
        var treeID: UUID
        var habit: Habit?
        var cheerBudget: CheerBudget
        var lastCheerCheck: Date
        var receivedDay: String
        var receivedCount: Int
        var celebratedDays: Int
        /// 축하한 목표 일수. 같은 목표를 두 번 축하하지 않게.
        var celebratedGoalDays: Int?

        static func fresh(now: Date) -> SavedState {
            SavedState(
                treeID: UUID(),
                habit: nil,
                cheerBudget: CheerBudget(now: now),
                lastCheerCheck: now,
                receivedDay: DayKey.make(now),
                receivedCount: 0,
                celebratedDays: 0
            )
        }
    }

    private(set) var saved: SavedState
    private(set) var forest: [PublicTree] = []
    private(set) var cohort: Cohort?
    private(set) var urge: UrgeSession?
    /// 방금 도착한 물방울 수. 화면이 보여 준 뒤 nil로 돌린다.
    var incomingCheers: Int?
    /// 새로 받은 배지. 화면이 축하한 뒤 nil로 돌린다.
    var newMilestone: Milestone?
    /// 방금 달성한 목표. 화면이 다음 목표를 고르게 한 뒤 nil로 돌린다.
    var reachedGoal: Goal?
    /// 이번 실행에서 물을 준 나무들.
    private(set) var wateredTreeIDs: Set<String> = []

    private let service: ForestService
    private let fileURL: URL

    init(service: ForestService, fileURL: URL = AppModel.defaultFileURL) {
        self.service = service
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let state = try? JSONDecoder().decode(SavedState.self, from: data) {
            saved = state
        } else {
            saved = .fresh(now: Date())
        }
    }

    nonisolated static var defaultFileURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("quiet-forest.json")
    }

    // MARK: - 읽기

    var habit: Habit? { saved.habit }
    var treeID: String { saved.treeID.uuidString }
    var treeName: String { TreeName.make(seed: saved.treeID) }

    func cheersLeft(at now: Date = Date()) -> Int {
        saved.cheerBudget.remaining(at: now)
    }

    func receivedToday(at now: Date = Date()) -> Int {
        saved.receivedDay == DayKey.make(now) ? saved.receivedCount : 0
    }

    // MARK: - 시작과 기록

    func begin(with habit: Habit) {
        saved.habit = habit
        saved.celebratedDays = Milestones.reached(cleanDays: habit.totalCleanDays(at: Date())).last?.days ?? 0
        save()
        publish()
    }

    func updateHabit(_ change: (inout Habit) -> Void) {
        guard var habit = saved.habit else { return }
        change(&habit)
        saved.habit = habit
        save()
    }

    func setGoal(_ goal: Goal) {
        reachedGoal = nil
        updateHabit { $0.goal = goal }
    }

    func recordSlip() {
        urge = nil
        updateHabit { $0.recordSlip(at: Date()) }
        publish()
    }

    /// 처음부터 다시. 숲에서도 새 나무, 새 이름이 된다.
    func resetEverything() {
        let oldID = treeID
        urge = nil
        saved = .fresh(now: Date())
        save()
        Task { try? await service.remove(treeID: oldID) }
    }

    // MARK: - 참기

    func startUrge() {
        urge = UrgeSession(startedAt: Date())
        saved.lastCheerCheck = Date()
        save()
        publish()
    }

    /// 버텼으면 succeeded = true. 중간에 닫으면 false (다시 한 건 아님).
    func endUrge(succeeded: Bool) {
        guard urge != nil else { return }
        urge = nil
        if succeeded {
            updateHabit { $0.recordUrgeWin() }
        }
        publish()
    }

    // MARK: - 숲

    func appBecameActive() {
        guard habit != nil else { return }
        publish()
        checkProgress()
        Task { await pollCheers() }
    }

    func refreshForest() async {
        guard let habit else { return }
        let now = Date()
        if let trees = try? await service.fetchForest() {
            forest = ForestStats.sorted(trees.filter { $0.id != treeID }, now: now)
        }
        if let same = try? await service.fetchCohort(startDay: DayKey.make(habit.startedAt)) {
            cohort = ForestStats.cohort(same, startDay: DayKey.make(habit.startedAt), now: now)
        }
    }

    /// 물 주기. 오늘 다 썼거나 이미 준 나무면 false.
    @discardableResult
    func water(_ tree: PublicTree) -> Bool {
        guard !wateredTreeIDs.contains(tree.id), saved.cheerBudget.spend(at: Date()) else { return false }
        wateredTreeIDs.insert(tree.id)
        save()
        Task { try? await service.sendCheer(to: tree.id) }
        return true
    }

    func pollCheers() async {
        let since = saved.lastCheerCheck
        let now = Date()
        guard let count = try? await service.fetchCheers(for: treeID, since: since) else { return }
        saved.lastCheerCheck = now
        let today = DayKey.make(now)
        if saved.receivedDay != today {
            saved.receivedDay = today
            saved.receivedCount = 0
        }
        if count > 0 {
            saved.receivedCount += count
            incomingCheers = count
        }
        save()
    }

    /// 목표 달성과 새 배지를 확인한다. 같은 날 둘 다면 목표 축하만 띄운다.
    func checkProgress() {
        guard let habit else { return }
        let days = habit.totalCleanDays(at: Date())
        let reached = Milestones.reached(cleanDays: days)

        if let goal = habit.goal, let target = goal.targetDays, days >= target, saved.celebratedGoalDays != target {
            saved.celebratedGoalDays = target
            saved.celebratedDays = max(saved.celebratedDays, reached.last?.days ?? 0)
            reachedGoal = goal
            save()
            return
        }

        guard let latest = reached.last, latest.days > saved.celebratedDays else { return }
        saved.celebratedDays = latest.days
        newMilestone = latest
        save()
    }

    // MARK: - 내부

    private func publish() {
        guard let habit else { return }
        let tree = PublicTree(id: treeID, name: treeName, habit: habit, urgingSince: urge?.startedAt, now: Date())
        Task { try? await service.publish(tree) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

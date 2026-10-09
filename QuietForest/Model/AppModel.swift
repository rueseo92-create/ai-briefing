import Foundation
import Observation
import ForestCore

/// 앱 상태. 끊는 것에 관한 정보는 전부 이 기기의 파일에만 저장한다.
@MainActor
@Observable
final class AppModel {
    /// 나중에 추가한 필드는 Optional로 두어 예전에 저장한 파일도 그대로 읽히게 한다.
    struct SavedState: Codable {
        var treeID: UUID
        var habit: Habit?
        var cheerBudget: CheerBudget
        var lastCheerCheck: Date
        /// v0.1에서 "오늘 받은 물"을 저장하던 곳. 지금은 inbox를 쓰고, 처음 읽을 때만 옮겨 온다.
        var receivedDay: String?
        var receivedCount: Int?
        var celebratedDays: Int
        /// 축하한 목표 일수. 같은 목표를 두 번 축하하지 않게.
        var celebratedGoalDays: Int?
        var inbox: CheerInbox?
        /// 참는 중에 앱이 꺼져도 돌아오면 이어서 보여 준다.
        var urgeStartedAt: Date?
        /// 알림. nil이면 아직 묻지 않았다.
        var remindersOn: Bool?
        /// 꾸미기. nil이면 아직 아무것도 생기지 않았다.
        var garden: GardenCollection?

        static func fresh(now: Date) -> SavedState {
            SavedState(
                treeID: UUID(),
                habit: nil,
                cheerBudget: CheerBudget(now: now),
                lastCheerCheck: now,
                celebratedDays: 0,
                inbox: CheerInbox(now: now)
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
    /// 새로 생긴 꾸밀 것. 화면이 알려 준 뒤 nil로 돌린다.
    var newGardenItems: [GardenItem]?

    private let service: ForestService
    private let fileURL: URL

    init(service: ForestService, fileURL: URL = AppModel.defaultFileURL) {
        self.service = service
        self.fileURL = fileURL
        let now = Date()
        var restoredUrge: UrgeSession?
        if let data = try? Data(contentsOf: fileURL),
           var state = try? JSONDecoder().decode(SavedState.self, from: data) {
            if state.inbox == nil {
                state.inbox = CheerInbox(day: state.receivedDay ?? DayKey.make(now), count: state.receivedCount ?? 0)
            }
            if let start = state.urgeStartedAt {
                // 숲에서 흔들리는 시간 안에 돌아왔으면 참기 화면을 이어서 보여 준다.
                if now.timeIntervalSince(start) < UrgeSession.publicWindow {
                    restoredUrge = UrgeSession(startedAt: start)
                } else {
                    state.urgeStartedAt = nil
                }
            }
            saved = state
        } else {
            saved = .fresh(now: now)
        }
        urge = restoredUrge
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
        saved.inbox?.count(at: now) ?? 0
    }

    func hasWatered(_ tree: PublicTree, at now: Date = Date()) -> Bool {
        saved.cheerBudget.hasWatered(tree.id, at: now)
    }

    var garden: GardenCollection { saved.garden ?? GardenCollection() }

    var remindersOn: Bool { saved.remindersOn ?? false }
    /// 알림을 켤지 아직 묻지 않았다.
    var shouldAskReminders: Bool { saved.remindersOn == nil }

    // MARK: - 시작과 기록

    func begin(with habit: Habit) {
        saved.habit = habit
        saved.celebratedDays = Milestones.reached(cleanDays: habit.totalCleanDays(at: Date())).last?.days ?? 0
        save()
        publish()
        planReminders()
        refreshGarden()
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
        planReminders()
    }

    func recordSlip() {
        clearUrge()
        updateHabit { $0.recordSlip(at: Date()) }
        publish()
        planReminders()
    }

    /// 처음부터 다시. 숲에서도 새 나무, 새 이름이 된다.
    func resetEverything() {
        let oldID = treeID
        let remindersOn = saved.remindersOn
        urge = nil
        saved = .fresh(now: Date())
        saved.remindersOn = remindersOn
        save()
        Notifier.cancelAll()
        Task { try? await service.remove(treeID: oldID) }
    }

    // MARK: - 알림

    /// 켜면 시스템 권한을 묻는다. 거절하면 꺼진 채로 둔다.
    func setReminders(_ on: Bool) async {
        if on {
            saved.remindersOn = await Notifier.requestPermission()
        } else {
            saved.remindersOn = false
            Notifier.cancelAll()
        }
        save()
        planReminders()
    }

    /// 다음 성장, 배지, 목표 알림을 다시 잡는다. 다시 하거나 목표를 바꾸면 시각이 달라진다.
    private func planReminders() {
        guard remindersOn, let habit else { return }
        let reminders = Reminders.upcoming(habit: habit, now: Date())
        Task { await Notifier.replaceGrowth(with: reminders) }
    }

    // MARK: - 참기

    func startUrge() {
        let session = UrgeSession(startedAt: Date())
        urge = session
        saved.urgeStartedAt = session.startedAt
        saved.lastCheerCheck = session.startedAt
        save()
        publish()
        if remindersOn { Notifier.schedule([Reminders.urgeDone(session)]) }
    }

    /// 버텼으면 succeeded = true. 중간에 닫으면 false (다시 한 건 아님).
    func endUrge(succeeded: Bool) {
        guard urge != nil else { return }
        clearUrge()
        if succeeded {
            updateHabit { $0.recordUrgeWin() }
            refreshGarden()
        }
        publish()
    }

    // MARK: - 숲

    func appBecameActive() {
        guard habit != nil else { return }
        publish()
        checkProgress()
        planReminders()
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
        guard saved.cheerBudget.spend(on: tree.id, at: Date()) else { return false }
        save()
        Task { try? await service.sendCheer(to: tree.id) }
        return true
    }

    func pollCheers() async {
        let since = saved.lastCheerCheck
        let now = Date()
        guard let cheers = try? await service.fetchCheers(for: treeID, since: since) else { return }
        saved.lastCheerCheck = now
        var inbox = saved.inbox ?? CheerInbox(now: now)
        let count = inbox.receive(cheers, now: now)
        saved.inbox = inbox
        if count > 0 {
            incomingCheers = count
        }
        save()
        if count > 0 { refreshGarden() }
    }

    /// 목표 달성과 새 배지를 확인한다. 같은 날 둘 다면 목표 축하만 띄운다.
    func checkProgress() {
        guard let habit else { return }
        refreshGarden()
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

    // MARK: - 꾸미기

    /// 잎·하늘은 바꾸고 장식은 달거나 뗀다. 장식이 꽉 찼으면 false.
    @discardableResult
    func toggleGarden(_ item: GardenItem) -> Bool {
        var garden = garden
        guard garden.toggle(item) else { return false }
        saved.garden = garden
        save()
        return true
    }

    /// 꾸미기 화면을 나갈 때. 바꾼 모습을 숲에도 한 번에 보낸다.
    func finishGardening() {
        var garden = garden
        garden.markSeen()
        saved.garden = garden
        save()
        publish()
    }

    /// 참은 날, 버텨 낸 순간, 받은 물로 새로 생긴 것이 있는지 본다.
    private func refreshGarden() {
        guard let habit else { return }
        var garden = garden
        let progress = GardenProgress(
            cleanDays: habit.totalCleanDays(at: Date()),
            urgeWins: habit.urgeWins,
            cheers: saved.inbox?.total ?? 0
        )
        let fresh = garden.update(with: progress)
        guard !fresh.isEmpty else { return }
        saved.garden = garden
        save()
        newGardenItems = (newGardenItems ?? []) + fresh
    }

    // MARK: - 내부

    private func clearUrge() {
        urge = nil
        saved.urgeStartedAt = nil
        save()
        Notifier.cancel([Reminders.urgeDoneID])
    }

    private func publish() {
        guard let habit else { return }
        let tree = PublicTree(id: treeID, name: treeName, habit: habit, style: garden.style, urgingSince: urge?.startedAt, now: Date())
        Task { try? await service.publish(tree) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

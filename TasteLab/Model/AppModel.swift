import Foundation
import Observation
import TasteCore

/// 앱 상태. 실험 기록은 전부 이 기기의 파일에만 저장한다.
@MainActor
@Observable
final class AppModel {
    /// 나중에 추가하는 필드는 Optional로 두어 예전 파일도 읽히게 한다.
    struct SavedState: Codable {
        var journal: Journal
        var picks: [Pick]
        /// 이 실험 세 장을 받은 주. "2026-W42"
        var picksWeek: String?
        var allowSponsored: Bool
        var onboarded: Bool
        /// 이번 주말에 해 볼 실험.
        var weekendPlanID: String?

        static let fresh = SavedState(journal: Journal(), picks: [], allowSponsored: true, onboarded: false)
    }

    private(set) var saved: SavedState
    private(set) var offers: [Experiment] = []
    /// 다섯 번째 기록을 남긴 순간 취향 정리를 보여 준다.
    var justUnlockedSummary = false

    private let offerService: OfferService
    private let fileURL: URL

    init(offerService: OfferService = SampleOfferService(), fileURL: URL = AppModel.defaultFileURL) {
        self.offerService = offerService
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let state = try? JSONDecoder().decode(SavedState.self, from: data) {
            saved = state
        } else {
            saved = .fresh
        }
    }

    nonisolated static var defaultFileURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("taste-lab.json")
    }

    // MARK: - 읽기

    var journal: Journal { saved.journal }
    var picks: [Pick] { saved.picks }
    var profile: TasteProfile { TasteProfile(journal: saved.journal) }
    var summary: TasteSummary? { Insight.summarize(saved.journal) }
    var allowSponsored: Bool { saved.allowSponsored }

    var catalog: [Experiment] { Catalog.all + offers }

    private var recommender: Recommender {
        Recommender(catalog: catalog, allowSponsored: saved.allowSponsored)
    }

    func hasTried(_ experiment: Experiment) -> Bool {
        saved.journal.hasTried(experiment.id)
    }

    func entry(for experiment: Experiment) -> Entry? {
        saved.journal.entries.last { $0.experimentID == experiment.id }
    }

    var allPicksDone: Bool {
        !saved.picks.isEmpty && saved.picks.allSatisfy { hasTried($0.experiment) }
    }

    func weekendIdeas(now: Date = Date()) -> [Experiment] {
        recommender.weekendIdeas(journal: saved.journal, now: now)
    }

    var weekendPlan: Experiment? {
        saved.weekendPlanID.flatMap { id in catalog.first { $0.id == id } }
    }

    // MARK: - 시작

    func finishOnboarding(allowSponsored: Bool) {
        saved.allowSponsored = allowSponsored
        saved.onboarded = true
        save()
        refreshWeekIfNeeded()
    }

    /// 앱을 열 때. 제안을 받아 오고, 주가 바뀌었으면 새 실험 세 장을 준다.
    func appBecameActive() async {
        if let fetched = try? await offerService.fetchOffers() {
            offers = fetched
        }
        refreshWeekIfNeeded()
    }

    func refreshWeekIfNeeded(now: Date = Date()) {
        guard saved.onboarded else { return }
        let week = Self.weekKey(now)
        guard saved.picksWeek != week || saved.picks.isEmpty else { return }
        var rng = SystemRandomNumberGenerator()
        let picks = recommender.weeklyPicks(journal: saved.journal, now: now, using: &rng)
        saved.picks = picks
        saved.picksWeek = week
        saved.journal.markShown(picks.map(\.id), at: now)
        save()
    }

    // MARK: - 실험

    /// "다른 걸로". 넘긴 실험은 한 달 동안 쉬고, 같은 자리에 다른 분야의 실험이 온다.
    func swap(_ pick: Pick, now: Date = Date()) {
        guard let index = saved.picks.firstIndex(of: pick) else { return }
        let others = saved.picks.filter { $0.id != pick.id }
        saved.journal.skip(pick.id, at: now)
        var rng = SystemRandomNumberGenerator()
        let replacement = recommender.pick(
            slot: pick.slot,
            journal: saved.journal,
            now: now,
            excluding: Set(saved.picks.map(\.id)),
            avoidDomains: Set(others.map(\.experiment.domain) + [pick.experiment.domain]),
            sponsorAllowed: !others.contains { $0.experiment.isSponsored },
            using: &rng
        )
        if let replacement {
            saved.picks[index] = replacement
            saved.journal.markShown([replacement.id], at: now)
        } else {
            saved.picks.remove(at: index)
        }
        save()
    }

    /// 이번 주 세 장을 다 했으면 한 장 더. 늘 처음 가 보는 쪽에서.
    func addOneMore(now: Date = Date()) {
        var rng = SystemRandomNumberGenerator()
        guard let extra = recommender.pick(
            slot: .fresh,
            journal: saved.journal,
            now: now,
            excluding: Set(saved.picks.map(\.id)),
            avoidDomains: Set(saved.picks.map(\.experiment.domain)),
            sponsorAllowed: !saved.picks.contains { $0.experiment.isSponsored },
            using: &rng
        ) else { return }
        saved.picks.append(extra)
        saved.journal.markShown([extra.id], at: now)
        save()
    }

    func record(_ experiment: Experiment, feeling: Feeling, why: [Tag], note: String) {
        let hadSummary = summary != nil
        saved.journal.record(Entry(experiment: experiment, feeling: feeling, why: why, note: note, at: Date()))
        if saved.weekendPlanID == experiment.id { saved.weekendPlanID = nil }
        save()
        if !hadSummary, summary != nil { justUnlockedSummary = true }
    }

    func planWeekend(_ experiment: Experiment?) {
        saved.weekendPlanID = experiment?.id
        save()
    }

    // MARK: - 설정

    /// 광고 실험을 끄면 지금 받은 광고 카드도 다른 실험으로 바꾼다.
    func setAllowSponsored(_ allow: Bool) {
        saved.allowSponsored = allow
        save()
        guard !allow else { return }
        for pick in saved.picks where pick.experiment.isSponsored && !hasTried(pick.experiment) {
            swap(pick)
        }
    }

    func resetEverything() {
        saved = .fresh
        save()
    }

    // MARK: - 내부

    static func weekKey(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", parts.yearForWeekOfYear ?? 0, parts.weekOfYear ?? 0)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

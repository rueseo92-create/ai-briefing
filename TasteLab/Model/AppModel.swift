import Foundation
import Observation
import TasteCore

/// 앱 상태. 실험 기록, 체크인 답, 위치, 사진은 전부 이 기기에만 저장한다.
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
        /// 마지막 체크인 답. 다음 주에 기본값으로 잡힌다.
        var checkIn: CheckIn
        /// 체크인을 마친 주.
        var checkedInWeek: String?
        var location: LocationSetting
        /// 지도에서 찾아 둔 동네 근처의 실제 장소.
        var nearby: NearbyPlaces?

        static let fresh = SavedState(
            journal: Journal(), picks: [], allowSponsored: true, onboarded: false,
            checkIn: .standard, location: .none
        )
    }

    private(set) var saved: SavedState
    private(set) var offers: [Experiment] = []
    /// 방금 만든 엽서. 화면이 보여 준 뒤 nil로 돌린다.
    var freshPostcard: Entry?
    /// 방금 생긴 우표.
    private(set) var freshStamps: [StampState] = []
    /// 다섯 번째 엽서를 만든 순간 취향 정리를 보여 준다.
    var justUnlockedSummary = false

    let photos: PhotoStore
    private let offerService: OfferService
    private let fileURL: URL

    init(offerService: OfferService = SampleOfferService(), fileURL: URL = AppModel.defaultFileURL, photos: PhotoStore = .standard) {
        self.offerService = offerService
        self.fileURL = fileURL
        self.photos = photos
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
        return folder.appendingPathComponent("taste-postcards.json")
    }

    // MARK: - 읽기

    var journal: Journal { saved.journal }
    var picks: [Pick] { saved.picks }
    var checkIn: CheckIn { saved.checkIn }
    var location: LocationSetting { saved.location }
    var nearby: NearbyPlaces? { saved.nearby }
    var profile: TasteProfile { TasteProfile(journal: saved.journal) }
    var summary: TasteSummary? { Insight.summarize(saved.journal) }
    var stamps: [StampState] { Stamps.board(saved.journal) }
    var allowSponsored: Bool { saved.allowSponsored }
    var postcards: [Entry] { saved.journal.entries.reversed() }

    var catalog: [Experiment] { Catalog.all + offers }

    var recommender: Recommender {
        Recommender(catalog: catalog, allowSponsored: saved.allowSponsored, checkIn: saved.checkIn, location: saved.location, nearby: saved.nearby)
    }

    /// 이번 주 체크인을 아직 안 했다.
    func needsCheckIn(now: Date = Date()) -> Bool {
        saved.checkedInWeek != Self.weekKey(now)
    }

    func hasTried(_ experiment: Experiment) -> Bool {
        saved.journal.hasTried(experiment.id)
    }

    func entry(for experiment: Experiment) -> Entry? {
        saved.journal.entries.last { $0.experimentID == experiment.id }
    }

    func travelMinutes(_ experiment: Experiment) -> Int? {
        recommender.travelMinutes(experiment)
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

    func finishOnboarding(location: LocationSetting, allowSponsored: Bool) {
        saved.location = location
        saved.allowSponsored = allowSponsored
        saved.onboarded = true
        save()
    }

    func appBecameActive() async {
        if let fetched = try? await offerService.fetchOffers() {
            offers = fetched
        }
        refreshWeekIfNeeded()
    }

    /// 주가 바뀌면 지난주 실험을 치우고 체크인을 기다린다.
    func refreshWeekIfNeeded(now: Date = Date()) {
        guard saved.onboarded, saved.picksWeek != Self.weekKey(now), saved.checkedInWeek != Self.weekKey(now) else { return }
        saved.picks = []
        saved.picksWeek = nil
        save()
    }

    // MARK: - 체크인

    /// 이번 주 체크인. 처음이면 실험 세 장을 받고, 주중에 바꾸면 안 맞는 카드만 바꾼다.
    func checkIn(_ answer: CheckIn, now: Date = Date()) {
        let week = Self.weekKey(now)
        saved.checkIn = answer
        let firstThisWeek = saved.checkedInWeek != week
        saved.checkedInWeek = week
        if firstThisWeek || saved.picksWeek != week || saved.picks.isEmpty {
            var rng = SystemRandomNumberGenerator()
            let picks = recommender.weeklyPicks(journal: saved.journal, now: now, using: &rng)
            saved.picks = picks
            saved.picksWeek = week
            saved.journal.markShown(picks.map(\.id), at: now)
        } else {
            replaceUnfitPicks(now: now)
        }
        save()
    }

    /// 대략적 위치를 새로 받았을 때.
    func updateApproximateLocation(_ coordinate: Coordinate) {
        saved.location.approximate = coordinate
        save()
    }

    /// 지도에서 동네 장소를 (다시) 찾아야 하면 그 출발점. 위치를 안 쓰거나 최근에 찾았으면 nil.
    func placeSearchOrigin(now: Date = Date()) -> Coordinate? {
        guard let origin = saved.location.origin else { return nil }
        if let nearby = saved.nearby, nearby.isFresh(for: origin, now: now) { return nil }
        return origin
    }

    /// 지도에서 찾은 장소로 바꾸고, 이제 갈 수 없게 된 카드는 다른 실험으로 바꾼다.
    func updateNearby(_ places: NearbyPlaces) {
        saved.nearby = places
        replaceUnfitPicks(now: Date())
        save()
    }

    func setLocation(_ location: LocationSetting) {
        saved.location = location
        replaceUnfitPicks(now: Date())
        save()
    }

    // MARK: - 실험

    /// "다른 걸로". 넘긴 실험은 한 달 쉬고, 같은 자리에 다른 구역의 실험이 온다.
    /// 돈이 들어서면 더 싼 것이 오고 이번 주 예산도 한 칸 낮아진다. 시간이 없어서면 더 짧은 것이 온다.
    func swap(_ pick: Pick, reason: SwapReason?, now: Date = Date()) {
        guard let index = saved.picks.firstIndex(of: pick) else { return }
        saved.journal.skip(pick.id, at: now)
        let extra: (Experiment) -> Bool
        switch reason {
        case .tooExpensive:
            saved.checkIn.budget = saved.checkIn.budget.lowered
            let cost = pick.experiment.effectiveCost
            extra = { $0.effectiveCost < cost || $0.effectiveCost == 0 }
        case .noTime:
            let total = pick.experiment.minutes + pick.travelMinutes
            let recommender = recommender
            extra = { $0.minutes + (recommender.travelMinutes($0) ?? 0) < total }
        case .notFeelingIt, nil:
            extra = { _ in true }
        }
        replace(at: index, now: now, extra: extra)
        if reason == .tooExpensive { replaceUnfitPicks(now: now) }
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

    /// 해 본 뒤 엽서 한 장. photo는 PhotoStore에 이미 저장한 파일 이름.
    func record(_ experiment: Experiment, feeling: Feeling, why: [Tag], note: String, photo: String?) {
        let before = saved.journal
        let hadSummary = summary != nil
        let entry = Entry(experiment: experiment, feeling: feeling, why: why, note: note, photo: photo, at: Date())
        saved.journal.record(entry)
        if saved.weekendPlanID == experiment.id { saved.weekendPlanID = nil }
        save()
        freshStamps = Stamps.newlyEarned(before: before, after: saved.journal)
        freshPostcard = entry
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
        if !allow { replaceUnfitPicks(now: Date()) }
        save()
    }

    func resetEverything() {
        let location = saved.location
        let nearby = saved.nearby
        saved = .fresh
        saved.location = location
        saved.nearby = nearby
        saved.onboarded = true
        photos.removeAll()
        save()
    }

    // MARK: - 내부

    static func weekKey(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", parts.yearForWeekOfYear ?? 0, parts.weekOfYear ?? 0)
    }

    /// 아직 안 한 카드 중 지금 체크인·위치·광고 설정에 안 맞는 것만 바꾼다. 넘긴 것으로 치지 않는다.
    private func replaceUnfitPicks(now: Date) {
        let recommender = recommender
        for pick in saved.picks where !hasTried(pick.experiment) {
            let unfit = !recommender.fits(pick.experiment) || (pick.experiment.isSponsored && !saved.allowSponsored)
            guard unfit, let index = saved.picks.firstIndex(of: pick) else { continue }
            replace(at: index, now: now, extra: { _ in true })
        }
    }

    private func replace(at index: Int, now: Date, extra: (Experiment) -> Bool) {
        let old = saved.picks[index]
        let others = saved.picks.filter { $0.id != old.id }
        var rng = SystemRandomNumberGenerator()
        let replacement = recommender.pick(
            slot: old.slot,
            journal: saved.journal,
            now: now,
            excluding: Set(saved.picks.map(\.id)),
            avoidDomains: Set(others.map(\.experiment.domain) + [old.experiment.domain]),
            sponsorAllowed: saved.allowSponsored && !others.contains { $0.experiment.isSponsored },
            where: extra,
            using: &rng
        )
        if let replacement {
            saved.picks[index] = replacement
            saved.journal.markShown([replacement.id], at: now)
        } else {
            saved.picks.remove(at: index)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

import Foundation
import Observation
import TasteCore

/// 앱 상태. 실험 기록, 체크인 답, 위치, 사진은 이 기기에 저장하고, 사용자가 켜면 본인 iCloud에 백업한다.
@MainActor
@Observable
final class AppModel {
    struct BackupState: Codable, Equatable {
        var enabled: Bool
        var lastBackupAt: Date?
        var uploadedPhotos: Set<String> = []
    }

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
        /// 동네의 이번 주 날씨.
        var weather: WeatherOutlook?
        /// "문 닫혀 있었어요", "그런 곳이 없었어요"라고 알려 준 곳.
        var blockedVenues: Set<String>?
        /// 알림. nil이면 아직 묻지 않았다.
        var remindersOn: Bool?
        /// 익명 주간 숫자 보내기. nil이면 꺼진 것으로 본다.
        var analyticsOn: Bool?
        var lastReportedWeek: String?
        /// 체크인한 주들. 익명 주간 숫자에만 쓴다.
        var checkedInWeeks: Set<String>?
        var backup: BackupState?

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
    private(set) var backupAvailable = false
    private(set) var isBackingUp = false

    let photos: PhotoStore
    private let offerService: OfferService
    private let backupService: BackupService?
    private let metricsService: MetricsService?
    private let reminderSink: ReminderSink?
    private let weatherProvider: WeatherProvider?
    private let placeSearcher: PlaceSearcher?
    private let fileURL: URL
    private var backupTask: Task<Void, Never>?

    init(
        offerService: OfferService = SampleOfferService(),
        backupService: BackupService? = nil,
        metricsService: MetricsService? = nil,
        reminderSink: ReminderSink? = nil,
        weatherProvider: WeatherProvider? = nil,
        placeSearcher: PlaceSearcher? = nil,
        fileURL: URL = AppModel.defaultFileURL,
        photos: PhotoStore = .standard
    ) {
        self.offerService = offerService
        self.backupService = backupService
        self.metricsService = metricsService
        self.reminderSink = reminderSink
        self.weatherProvider = weatherProvider
        self.placeSearcher = placeSearcher
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
    var nearby: NearbyPlaces? { saved.nearby?.excluding(saved.blockedVenues ?? []) }
    var weather: WeatherOutlook? { saved.weather }
    var profile: TasteProfile { TasteProfile(journal: saved.journal) }
    var summary: TasteSummary? { Insight.summarize(saved.journal) }
    var stamps: [StampState] { Stamps.board(saved.journal) }
    var allowSponsored: Bool { saved.allowSponsored }
    var postcards: [Entry] { saved.journal.entries.reversed() }
    var remindersOn: Bool { saved.remindersOn ?? false }
    var shouldAskReminders: Bool { saved.remindersOn == nil && reminderSink != nil && !needsCheckIn() }
    var analyticsOn: Bool { saved.analyticsOn ?? false }
    var canSendAnalytics: Bool { metricsService != nil }
    var backupOn: Bool { saved.backup?.enabled ?? false }
    var lastBackupAt: Date? { saved.backup?.lastBackupAt }

    var catalog: [Experiment] { Catalog.all + offers }

    var recommender: Recommender {
        Recommender(
            catalog: catalog, allowSponsored: saved.allowSponsored, checkIn: saved.checkIn,
            location: saved.location, nearby: nearby, weather: saved.weather
        )
    }

    /// 이번 주 체크인을 아직 안 했다.
    func needsCheckIn(now: Date = Date()) -> Bool {
        saved.checkedInWeek != Week.key(now)
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

    func finishOnboarding(location: LocationSetting, allowSponsored: Bool, analytics: Bool, backup: Bool) {
        saved.location = location
        saved.allowSponsored = allowSponsored
        saved.analyticsOn = analytics
        if backup { saved.backup = BackupState(enabled: true) }
        saved.onboarded = true
        save()
    }

    func appBecameActive(now: Date = Date()) async {
        if let fetched = try? await offerService.fetchOffers() {
            offers = fetched
        }
        refreshWeekIfNeeded(now: now)
        await refreshReminders(now: now)
        await sendLastWeekReport(now: now)
        if let backupService { backupAvailable = await backupService.isAvailable() }
    }

    /// 주가 바뀌면 지난주 실험을 치우고 체크인을 기다린다.
    func refreshWeekIfNeeded(now: Date = Date()) {
        let week = Week.key(now)
        guard saved.onboarded, saved.picksWeek != week, saved.checkedInWeek != week else { return }
        saved.picks = []
        saved.picksWeek = nil
        save()
    }

    // MARK: - 체크인

    /// 실험을 받기 전에: 동네 장소(한 달에 한 번)와 이번 주 날씨(반나절에 한 번)를 확인한다.
    func prepareWeek(now: Date = Date()) async {
        guard let origin = saved.location.origin else { return }
        if let placeSearcher, placeSearchOrigin(now: now) != nil, let places = await placeSearcher.search(around: origin) {
            saved.nearby = places
        }
        if let weatherProvider, !(saved.weather?.isFresh(for: origin, now: now) ?? false),
           let outlook = await weatherProvider.outlook(for: origin) {
            saved.weather = outlook
        }
        save()
    }

    /// 이번 주 체크인. 처음이면 실험 세 장을 받고, 주중에 바꾸면 안 맞는 카드만 바꾼다.
    func checkIn(_ answer: CheckIn, now: Date = Date()) {
        let week = Week.key(now)
        saved.checkIn = answer
        let firstThisWeek = saved.checkedInWeek != week
        saved.checkedInWeek = week
        saved.checkedInWeeks = (saved.checkedInWeeks ?? []).union([week])
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
        Task { await refreshReminders(now: now) }
    }

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
        saved.journal.recordSwap(reason, at: now)
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
        Task { await refreshReminders(now: Date()) }
    }

    func recordCodeCopy() {
        saved.journal.recordCodeCopy(at: Date())
        save()
    }

    /// 문제 신고. 장소 문제면 그곳을 다시 권하지 않는다. 메일로 보낼 내용(장소 이름, 문제 종류만)을 돌려준다.
    @discardableResult
    func reportProblem(_ problem: ProblemReport, experiment: Experiment, venue: Venue?, appVersion: String) -> URL? {
        if problem.blocksVenue, let venue {
            saved.blockedVenues = (saved.blockedVenues ?? []).union([NearbyPlaces.blockKey(venue)])
            replaceUnfitPicks(now: Date())
            save()
        }
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = AppConfig.feedbackEmail
        let lines = [
            "문제: \(problem.title)",
            "실험: \(experiment.title) (\(experiment.id))",
            "장소: \(venue?.name ?? "-")",
            "앱 버전: \(appVersion)",
            "",
            "더 알려 주실 게 있으면 적어 주세요.",
        ]
        parts.queryItems = [
            URLQueryItem(name: "subject", value: "[취향 엽서] \(problem.title)"),
            URLQueryItem(name: "body", value: lines.joined(separator: "\n")),
        ]
        return parts.url
    }

    // MARK: - 알림

    /// 켜면 시스템 권한을 묻는다. 거절하면 꺼진 채로 둔다.
    func setReminders(_ on: Bool) async {
        guard let reminderSink else { return }
        if on {
            saved.remindersOn = await reminderSink.requestPermission()
        } else {
            saved.remindersOn = false
            await reminderSink.cancelAll()
        }
        save()
        await refreshReminders(now: Date())
    }

    /// 다음 월요일 체크인, 키트 주문 마감, 토요일 주말 계획 알림을 다시 잡는다.
    func refreshReminders(now: Date) async {
        guard remindersOn, let reminderSink else { return }
        await reminderSink.replace(with: WeeklyReminders.plan(now: now, weekendPlan: weekendPlan))
    }

    // MARK: - 익명 주간 숫자

    func setAnalytics(_ on: Bool) {
        saved.analyticsOn = on
        save()
    }

    /// 지난주 숫자를 한 번 보낸다. 켰을 때만, 실패하면 다음에 다시.
    func sendLastWeekReport(now: Date) async {
        guard analyticsOn, let metricsService, saved.onboarded else { return }
        let lastWeek = Week.key(now.addingTimeInterval(-7 * 86_400))
        guard saved.lastReportedWeek != lastWeek else { return }
        let report = WeeklyReport.make(week: lastWeek, journal: saved.journal, checkedIn: saved.checkedInWeeks?.contains(lastWeek) ?? false)
        do {
            try await metricsService.send(report)
            saved.lastReportedWeek = lastWeek
            save()
        } catch {}
    }

    // MARK: - iCloud 백업

    func setBackup(_ on: Bool) {
        if on {
            saved.backup = BackupState(enabled: true, lastBackupAt: saved.backup?.lastBackupAt, uploadedPhotos: saved.backup?.uploadedPhotos ?? [])
        } else {
            saved.backup?.enabled = false
        }
        save()
    }

    /// 바뀐 뒤 잠깐 기다렸다가 한 번에 올린다.
    private func scheduleBackup() {
        guard backupOn, backupService != nil else { return }
        backupTask?.cancel()
        backupTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await self?.backupNow()
        }
    }

    func backupNow() async {
        guard backupOn, let backupService, !isBackingUp else { return }
        isBackingUp = true
        defer { isBackingUp = false }
        let uploaded = saved.backup?.uploadedPhotos ?? []
        let names = Set(saved.journal.entries.compactMap(\.photo))
        var newPhotos: [String: URL] = [:]
        for name in names.subtracting(uploaded) where FileManager.default.fileExists(atPath: photos.url(for: name).path) {
            newPhotos[name] = photos.url(for: name)
        }
        guard let data = try? JSONEncoder().encode(saved) else { return }
        do {
            try await backupService.upload(state: data, photos: newPhotos)
            saved.backup?.uploadedPhotos = uploaded.union(newPhotos.keys)
            saved.backup?.lastBackupAt = Date()
            write()
        } catch {}
    }

    /// iCloud에서 엽서를 가져온다. 이 기기에 기록이 없을 때만. 가져왔으면 true.
    func restoreFromBackup() async -> Bool {
        guard let backupService, saved.journal.entries.isEmpty,
              let data = try? await backupService.downloadState(),
              var state = try? JSONDecoder().decode(SavedState.self, from: data) else { return false }
        let names = state.journal.entries.compactMap(\.photo)
        try? await backupService.downloadPhotos(names, into: photos)
        state.onboarded = true
        state.backup = BackupState(enabled: true, lastBackupAt: state.backup?.lastBackupAt, uploadedPhotos: Set(names))
        saved = state
        write()
        return true
    }

    // MARK: - 설정

    /// 광고 실험을 끄면 지금 받은 광고 카드도 다른 실험으로 바꾼다.
    func setAllowSponsored(_ allow: Bool) {
        saved.allowSponsored = allow
        if !allow { replaceUnfitPicks(now: Date()) }
        save()
    }

    /// 엽서, 사진, 기록을 모두 지운다. iCloud 백업도 지운다. 위치와 동네 지도, 알림·통계 설정은 남긴다.
    func resetEverything() {
        let keep = saved
        let photoNames = saved.journal.entries.compactMap(\.photo)
        saved = .fresh
        saved.onboarded = true
        saved.location = keep.location
        saved.nearby = keep.nearby
        saved.remindersOn = keep.remindersOn
        saved.analyticsOn = keep.analyticsOn
        saved.backup = keep.backup.map { BackupState(enabled: $0.enabled) }
        photos.removeAll()
        save()
        if let backupService, keep.backup?.enabled == true {
            Task { try? await backupService.deleteAll(photoNames: photoNames) }
        }
    }

    // MARK: - 내부

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
        write()
        scheduleBackup()
    }

    private func write() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

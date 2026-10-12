import XCTest
@testable import TasteCore

private let day: TimeInterval = 86_400
/// 2026-10-12 (월) 09:00 UTC
private let monday = Date(timeIntervalSince1970: 1_791_795_600)

private var utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func experiment(_ id: String, _ domain: Domain, _ tags: [Tag], sponsor: Sponsorship? = nil) -> Experiment {
    Experiment(id: id, title: id, detail: "", domain: domain, tags: tags, minutes: 10, place: .home, sponsor: sponsor)
}

private func journal(_ items: [(Experiment, Feeling, [Tag])], at now: Date = monday) -> Journal {
    var journal = Journal()
    for (experiment, feeling, why) in items {
        journal.record(Entry(experiment: experiment, feeling: feeling, why: why, at: now))
    }
    return journal
}

final class CatalogTests: XCTestCase {
    func testCatalogIsBalancedAndWellFormed() {
        let all = Catalog.all + SampleOffers.all
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "id가 겹치면 기록이 섞인다")
        XCTAssertEqual(Catalog.all.count, 64)
        for domain in Domain.allCases {
            XCTAssertEqual(Catalog.all.filter { $0.domain == domain }.count, 8, domain.title)
        }
        for item in all {
            XCTAssertFalse(item.tags.isEmpty, item.id)
            XCTAssertLessThanOrEqual(item.tags.count, 3, item.id)
            XCTAssertEqual(Set(item.tags).count, item.tags.count, item.id)
            XCTAssertGreaterThan(item.minutes, 0, item.id)
        }
        XCTAssertTrue(Catalog.all.allSatisfy { $0.sponsor == nil && $0.kit == nil }, "기본 카드에는 광고가 없다")
        XCTAssertTrue(SampleOffers.sponsored.allSatisfy(\.isSponsored))
        XCTAssertTrue(SampleOffers.kits.allSatisfy { $0.kit != nil })
    }

    func testEntryKeepsOnlyReasonsFromTheExperiment() {
        let cafe = experiment("cafe", .place, [.quiet, .solo])
        let entry = Entry(experiment: cafe, feeling: .liked, why: [.quiet, .moving], at: monday)
        XCTAssertEqual(entry.why, [.quiet])
        XCTAssertEqual(entry.domain, .place)
    }
}

final class ProfileTests: XCTestCase {
    func testScoresFollowReasons() {
        let cafe = experiment("cafe", .place, [.quiet, .solo, .novel])
        let party = experiment("party", .people, [.together, .novel])
        let profile = TasteProfile(journal: journal([(cafe, .liked, [.quiet]), (party, .disliked, [.together])]))
        XCTAssertEqual(profile.tagScores[.quiet], 3)
        XCTAssertEqual(profile.tagScores[.solo], 1)
        XCTAssertEqual(profile.tagScores[.novel], 0)
        XCTAssertEqual(profile.tagScores[.together], -3)
        XCTAssertEqual(profile.topTags(), [.quiet, .solo])
        XCTAssertEqual(profile.dislikedTags, [.together])
        XCTAssertFalse(profile.dislikedTags.contains(.novel), "좋았던 것과 별로였던 것에 다 있으면 0")
        XCTAssertEqual(profile.likedDomains, [.place])
        XCTAssertTrue(profile.hasDislikedTag(party))
        XCTAssertEqual(profile.unexplored.count, Domain.allCases.count - 2)
    }

    func testDomainStates() {
        XCTAssertEqual(DomainStat().state, .unexplored)
        XCTAssertEqual(DomainStat(tried: 1, liked: 0).state, .exploring)
        XCTAssertEqual(DomainStat(tried: 3, liked: 2, disliked: 1).state, .favorite)
        XCTAssertEqual(DomainStat(tried: 2, liked: 0, disliked: 2).state, .notForMe)
        XCTAssertEqual(DomainStat(tried: 9).light, 1)
        XCTAssertEqual(DomainStat(tried: 2).light, 0.5)
    }
}

final class InsightTests: XCTestCase {
    func testNeedsAFewEntries() {
        let cafe = experiment("cafe", .place, [.quiet])
        XCTAssertNil(Insight.summarize(journal(Array(repeating: (cafe, .liked, [.quiet]), count: 4))))
    }

    func testFindsTheCommonReasonAcrossDomains() throws {
        let items: [(Experiment, Feeling, [Tag])] = [
            (experiment("cafe", .place, [.quiet, .solo]), .liked, [.quiet]),
            (experiment("jazz", .sound, [.quiet, .slow]), .liked, [.quiet]),
            (experiment("poem", .mind, [.quiet, .slow]), .liked, [.quiet, .slow]),
            (experiment("party", .people, [.together, .novel]), .disliked, [.together]),
            (experiment("run", .body, [.moving]), .meh, []),
        ]
        let summary = try XCTUnwrap(Insight.summarize(journal(items)))
        XCTAssertEqual(summary.headline, "조용한 것에 마음이 가는 사람")
        XCTAssertEqual(summary.topTags.first, .quiet)
        XCTAssertTrue(summary.lines.contains("소리, 공간, 글과 생각처럼 분야는 달라도 ‘조용해서’가 공통점이에요."))
        XCTAssertTrue(summary.lines.contains("‘함께라서’는 아직 잘 안 맞았어요. 별로인 걸 아는 것도 취향이에요."))
        XCTAssertEqual(summary.nextFrontier, .taste)
    }

    func testNoLikesYetStillGetsAKindSummary() throws {
        let meh = experiment("x", .body, [.moving])
        let summary = try XCTUnwrap(Insight.summarize(journal(Array(repeating: (meh, .meh, []), count: 5))))
        XCTAssertEqual(summary.headline, "아직 찾는 중인 사람")
    }
}

final class RecommenderTests: XCTestCase {
    private let recommender = Recommender(catalog: Catalog.all, allowSponsored: false)

    func testFirstWeekSpreadsAcrossDomains() {
        var rng = SeededRandom(seed: 1)
        let picks = recommender.weeklyPicks(journal: Journal(), now: monday, using: &rng)
        XCTAssertEqual(picks.count, 3)
        XCTAssertEqual(Set(picks.map(\.experiment.domain)).count, 3)
        XCTAssertTrue(picks.allSatisfy { $0.slot == .fresh })
        XCTAssertEqual(picks[0].reason, "첫 실험은 여러 지역에서 하나씩 골랐어요")
    }

    func testMixesConfirmSideStepAndFresh() throws {
        let liked = Catalog.all.filter { $0.id == "place-new-cafe" || $0.id == "place-library" }
        let history = journal(liked.map { ($0, .liked, [.quiet]) })
        for seed in 0..<50 {
            var rng = SeededRandom(seed: UInt64(seed))
            let picks = recommender.weeklyPicks(journal: history, now: monday, using: &rng)
            XCTAssertEqual(picks.map(\.slot), [.confirm, .sideStep, .fresh])
            XCTAssertEqual(Set(picks.map(\.experiment.domain)).count, 3, "세 장은 모두 다른 분야")
            XCTAssertFalse(picks.contains { history.hasTried($0.id) }, "해 본 건 다시 권하지 않는다")

            let side = picks[1]
            XCTAssertNotEqual(side.experiment.domain, .place, "옆으로 한 칸은 익숙한 분야가 아니다")
            XCTAssertTrue(side.experiment.tags.contains(.quiet) || side.experiment.tags.contains(.solo) || side.experiment.tags.contains(.slow))

            let fresh = picks[2]
            XCTAssertNotEqual(fresh.experiment.domain, .place)
            XCTAssertTrue(fresh.reason.hasPrefix("아직 안 가 본"))
        }
    }

    /// 매주 실험을 받기만 하고 하지 않아도, 석 주 안에는 같은 카드가 다시 나오지 않는다.
    func testEveryWeekBringsSomethingNew() {
        var history = Journal()
        var seen = Set<String>()
        var rng = SeededRandom(seed: 7)
        for week in 0..<3 {
            let now = monday.addingTimeInterval(Double(week) * 7 * day)
            let picks = recommender.weeklyPicks(journal: history, now: now, using: &rng)
            XCTAssertEqual(picks.count, 3)
            for pick in picks {
                XCTAssertFalse(seen.contains(pick.id), "\(pick.id)가 \(week)주차에 또 나왔다")
                seen.insert(pick.id)
            }
            history.markShown(picks.map(\.id), at: now)
        }
    }

    func testSkippedCardsRestForAMonth() {
        let one = Recommender(catalog: [experiment("a", .sound, [.quiet]), experiment("b", .sound, [.quiet])], allowSponsored: false)
        var history = Journal()
        history.skip("a", at: monday)
        var rng = SeededRandom(seed: 3)
        XCTAssertEqual(one.weeklyPicks(journal: history, now: monday + day, count: 2, using: &rng).map(\.id), ["b"])
        XCTAssertEqual(Set(one.weeklyPicks(journal: history, now: monday + 31 * day, count: 2, using: &rng).map(\.id)), ["a", "b"])
    }

    func testRunsOutGracefullyAndReusesRecentlyShown() {
        let tiny = Recommender(catalog: [experiment("a", .sound, [.quiet])], allowSponsored: false)
        var history = Journal()
        history.markShown(["a"], at: monday)
        var rng = SeededRandom(seed: 1)
        XCTAssertEqual(tiny.weeklyPicks(journal: history, now: monday, using: &rng).map(\.id), ["a"])
        history.record(Entry(experiment: experiment("a", .sound, [.quiet]), feeling: .liked, why: [], at: monday))
        XCTAssertTrue(tiny.weeklyPicks(journal: history, now: monday, using: &rng).isEmpty)
    }
}

final class SponsoredTests: XCTestCase {
    private let history = journal([
        (experiment("cafe", .place, [.quiet, .making]), .liked, [.quiet, .making]),
        (experiment("lib", .place, [.quiet, .novel]), .liked, [.quiet]),
        (experiment("party", .people, [.together]), .disliked, [.together]),
    ])

    func testAtMostOneAdNeverInConfirmAndNeverAgainstTaste() {
        let ads = [
            experiment("ad-craft", .hands, [.making, .quiet], sponsor: Sponsorship(brand: "A", benefit: "x")),
            experiment("ad-tea", .taste, [.quiet, .sensory], sponsor: Sponsorship(brand: "B", benefit: "y")),
            experiment("ad-club", .sound, [.together, .quiet], sponsor: Sponsorship(brand: "C", benefit: "z")),
        ]
        let recommender = Recommender(catalog: Catalog.all + ads, allowSponsored: true)
        var adSeen = 0
        for seed in 0..<200 {
            var rng = SeededRandom(seed: UInt64(seed))
            let picks = recommender.weeklyPicks(journal: history, now: monday, using: &rng)
            let sponsored = picks.filter(\.experiment.isSponsored)
            XCTAssertLessThanOrEqual(sponsored.count, 1)
            XCTAssertFalse(sponsored.contains { $0.slot == .confirm })
            XCTAssertFalse(sponsored.contains { $0.id == "ad-club" }, "싫어한 이유가 있는 광고는 나오지 않는다")
            adSeen += sponsored.count
        }
        XCTAssertGreaterThan(adSeen, 0, "맞는 광고는 나올 수 있어야 한다")
    }

    func testAdsCanBeTurnedOffAndExpire() {
        let ad = experiment("ad", .hands, [.making, .quiet], sponsor: Sponsorship(brand: "A", benefit: "x", endsAt: monday + day))
        let off = Recommender(catalog: Catalog.all + [ad], allowSponsored: false)
        let on = Recommender(catalog: Catalog.all + [ad], allowSponsored: true)
        for seed in 0..<100 {
            var rng = SeededRandom(seed: UInt64(seed))
            XCTAssertFalse(off.weeklyPicks(journal: history, now: monday, using: &rng).contains { $0.experiment.isSponsored })
            XCTAssertFalse(on.weeklyPicks(journal: history, now: monday + 2 * day, using: &rng).contains { $0.experiment.isSponsored })
        }
    }

    func testWeekendIdeasFollowTaste() {
        let recommender = Recommender(catalog: Catalog.all + SampleOffers.all, allowSponsored: true)
        let ideas = recommender.weekendIdeas(journal: history, now: monday)
        XCTAssertFalse(ideas.isEmpty)
        XCTAssertTrue(ideas.allSatisfy { $0.kit != nil })
        XCTAssertTrue(ideas.first?.tags.contains(.making) ?? false, "만드는 걸 좋아했으니 만드는 키트가 먼저")
    }
}

final class WeekendTests: XCTestCase {
    func testUpcomingSaturday() {
        let saturday = monday.addingTimeInterval(5 * day - 9 * 3600)
        XCTAssertEqual(Weekend.upcomingSaturday(from: monday, calendar: utc), saturday)
        XCTAssertEqual(Weekend.upcomingSaturday(from: saturday + 3600, calendar: utc), saturday)
        XCTAssertEqual(Weekend.upcomingSaturday(from: saturday + day + 3600, calendar: utc), saturday + 7 * day)
    }

    func testOrderByThursdayNoonForTwoDayDelivery() {
        let kit = Kit(name: "k", contents: [], price: 10_000, leadDays: 2)
        let saturday = Weekend.upcomingSaturday(from: monday, calendar: utc)
        let thursdayNoon = saturday - 2 * day + 12 * 3600
        XCTAssertEqual(Weekend.status(of: kit, now: monday, calendar: utc), .thisWeekend(orderBy: thursdayNoon, saturday: saturday))
        XCTAssertEqual(
            Weekend.status(of: kit, now: thursdayNoon + 60, calendar: utc),
            .nextWeekend(orderBy: thursdayNoon + 7 * day, saturday: saturday + 7 * day)
        )
    }

    func testSlowKitsSkipAheadUntilTheyCanArrive() {
        let slow = Kit(name: "slow", contents: [], price: 0, leadDays: 9)
        let status = Weekend.status(of: slow, now: monday, calendar: utc)
        XCTAssertGreaterThan(status.orderBy, monday)
        XCTAssertEqual(status.saturday.timeIntervalSince(status.orderBy), 9 * day - 12 * 3600)
    }
}

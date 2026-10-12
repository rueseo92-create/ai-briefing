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

private let cityHall = Coordinate(latitude: 37.5663, longitude: 126.9779)
private let gangnamStation = Coordinate(latitude: 37.4979, longitude: 127.0276)
private let anything = CheckIn(budget: .any, energy: .high, time: .fullDay, company: .together)

private func experiment(
    _ id: String, _ domain: Domain, _ tags: [Tag], minutes: Int = 10, place: Place = .home,
    cost: Int = 0, company: Bool = false, sponsor: Sponsorship? = nil
) -> Experiment {
    Experiment(id: id, title: id, detail: "", domain: domain, tags: tags, minutes: minutes, place: place, cost: cost, needsCompany: company, sponsor: sponsor)
}

private func journal(_ items: [(Experiment, Feeling, [Tag])], at now: Date = monday) -> Journal {
    var journal = Journal()
    for (experiment, feeling, why) in items {
        journal.record(Entry(experiment: experiment, feeling: feeling, why: why, at: now))
    }
    return journal
}

private func card(_ id: String) -> Experiment {
    Catalog.all.first { $0.id == id }!
}

final class CatalogTests: XCTestCase {
    func testCatalogIsBalancedAndWellFormed() {
        let all = Catalog.all + SampleOffers.all
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "id가 겹치면 기록이 섞인다")
        XCTAssertEqual(Catalog.all.count, 80)
        for domain in Domain.allCases {
            XCTAssertEqual(Catalog.all.filter { $0.domain == domain }.count, 10, domain.title)
        }
        for item in all {
            XCTAssertFalse(item.tags.isEmpty, item.id)
            XCTAssertLessThanOrEqual(item.tags.count, 3, item.id)
            XCTAssertEqual(Set(item.tags).count, item.tags.count, item.id)
            XCTAssertGreaterThan(item.minutes, 0, item.id)
        }
        XCTAssertGreaterThan(Catalog.all.filter { $0.cost == 0 }.count, Catalog.all.count / 2, "절반 이상은 0원")
        XCTAssertTrue(Catalog.all.allSatisfy { $0.sponsor == nil && $0.kit == nil }, "기본 카드에는 광고가 없다")
        XCTAssertTrue(Catalog.all.allSatisfy { if case .venue = $0.place { return false } else { return true } }, "기본 카드는 특정 장소가 없다")
        XCTAssertTrue(SampleOffers.sponsored.allSatisfy(\.isSponsored))
        XCTAssertTrue(SampleOffers.kits.allSatisfy { $0.kit != nil })
    }

    /// 체크인을 어떻게 고르든 실험이 바닥나지 않아야 한다.
    func testEveryCheckInHasEnoughCards() {
        for budget in CheckIn.Budget.allCases {
            for energy in CheckIn.Energy.allCases {
                for time in CheckIn.TimeBudget.allCases {
                    let checkIn = CheckIn(budget: budget, energy: energy, time: time, company: .solo)
                    let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, checkIn: checkIn)
                    let fitting = Catalog.all.filter(recommender.fits)
                    XCTAssertGreaterThanOrEqual(fitting.count, 9, "\(budget) \(energy) \(time)")
                    XCTAssertGreaterThanOrEqual(Set(fitting.map(\.domain)).count, 3, "\(budget) \(energy) \(time)")
                }
            }
        }
    }

    func testEntryKeepsOnlyReasonsFromTheExperiment() {
        let entry = Entry(experiment: experiment("cafe", .breath, [.quiet, .solo]), feeling: .liked, why: [.quiet, .moving], photo: "a.jpg", at: monday)
        XCTAssertEqual(entry.why, [.quiet])
        XCTAssertEqual(entry.domain, .breath)
        XCTAssertEqual(entry.photo, "a.jpg")
        XCTAssertEqual(Feeling.liked.stamp, "좋았어요")
        XCTAssertNil(Feeling.meh.stamp)
        XCTAssertEqual(Feeling.disliked.stamp, "다음엔 다르게")
    }
}

final class CheckInTests: XCTestCase {
    func testBudgetUsesThePriceYouActuallyPay() {
        let free = CheckIn(budget: .free, energy: .high, time: .fullDay, company: .together)
        XCTAssertTrue(free.allows(experiment("a", .rest, [.quiet]), travelMinutes: 0))
        XCTAssertFalse(free.allows(experiment("b", .rest, [.quiet], cost: 5_000), travelMinutes: 0))
        let freeClass = experiment("c", .movement, [.moving], cost: 25_000, sponsor: Sponsorship(brand: "x", benefit: "무료", priceAfterBenefit: 0))
        XCTAssertTrue(free.allows(freeClass, travelMinutes: 0), "혜택 뒤 0원이면 예산 0원에도 나온다")
        let tenK = CheckIn(budget: .under10k, energy: .high, time: .fullDay, company: .together)
        XCTAssertTrue(tenK.allows(experiment("d", .food, [.sensory], cost: 10_000), travelMinutes: 0))
        XCTAssertFalse(tenK.allows(experiment("e", .food, [.sensory], cost: 10_001), travelMinutes: 0))
        XCTAssertEqual(CheckIn.Budget.under30k.lowered, .under10k)
        XCTAssertEqual(CheckIn.Budget.free.lowered, .free)
    }

    func testLowEnergyMeansShortAndStill() {
        let low = CheckIn(budget: .any, energy: .low, time: .fullDay, company: .together)
        XCTAssertTrue(low.allows(experiment("a", .breath, [.quiet], minutes: 15), travelMinutes: 0))
        XCTAssertFalse(low.allows(experiment("b", .breath, [.quiet], minutes: 30), travelMinutes: 0))
        XCTAssertFalse(low.allows(experiment("c", .movement, [.moving], minutes: 5), travelMinutes: 0))
    }

    /// 시간은 실험 시간 + 오가는 시간으로 따진다.
    func testTimeCountsTheTripToo() {
        let short = CheckIn(budget: .any, energy: .high, time: .short, company: .together)
        XCTAssertTrue(short.allows(experiment("a", .rest, [.slow], minutes: 25), travelMinutes: 0))
        XCTAssertTrue(short.allows(experiment("b", .nature, [.outdoors], minutes: 10), travelMinutes: 20))
        XCTAssertFalse(short.allows(experiment("c", .nature, [.outdoors], minutes: 15), travelMinutes: 20), "35분")
        XCTAssertFalse(short.allows(experiment("d", .nature, [.outdoors], minutes: 5), travelMinutes: 25), "오가는 시간이 20분을 넘는다")
        XCTAssertFalse(short.allows(experiment("e", .nature, [.outdoors], minutes: 5), travelMinutes: nil), "갈 수 없는 곳")
        let half = CheckIn(budget: .any, energy: .high, time: .halfDay, company: .together)
        XCTAssertTrue(half.allows(experiment("f", .making, [.making], minutes: 120), travelMinutes: 60))
        XCTAssertFalse(half.allows(experiment("g", .making, [.making], minutes: 60), travelMinutes: 61))
    }

    func testAloneSkipsWhatNeedsCompany() {
        let pair = experiment("a", .connection, [.together], company: true)
        XCTAssertFalse(CheckIn(budget: .any, energy: .high, time: .fullDay, company: .solo).allows(pair, travelMinutes: 0))
        XCTAssertTrue(anything.allows(pair, travelMinutes: 0))
    }
}

final class TravelTests: XCTestCase {
    func testDistanceAndRoundTrip() throws {
        let km = cityHall.distanceKm(to: gangnamStation)
        XCTAssertEqual(km, 8.8, accuracy: 0.5)
        let venue = Place.venue(Venue(name: "강남", coordinate: gangnamStation))
        let transit = try XCTUnwrap(Travel.roundTripMinutes(to: venue, from: cityHall, mode: .transit))
        XCTAssertEqual(Double(transit), 2 * (km * 1.3 / 18 * 60 + 10), accuracy: 1)
        let walk = try XCTUnwrap(Travel.roundTripMinutes(to: venue, from: cityHall, mode: .walk))
        XCTAssertGreaterThan(walk, transit)
        XCTAssertNil(Travel.roundTripMinutes(to: venue, from: nil, mode: .car), "위치가 없으면 특정 장소는 갈 수 없다")
        XCTAssertEqual(Travel.roundTripMinutes(to: .nearby(roundTripMinutes: 20), from: nil, mode: .car), 20)
        XCTAssertEqual(Travel.roundTripMinutes(to: .home, from: nil, mode: .walk), 0)
    }

    func testOriginFollowsTheChosenKind() {
        let mapo = Regions.all.first { $0.name == "서울 마포구" }!
        XCTAssertEqual(LocationSetting(kind: .neighborhood, region: mapo).origin, mapo.coordinate)
        XCTAssertEqual(LocationSetting(kind: .approximate, region: mapo, approximate: cityHall).origin, cityHall)
        XCTAssertEqual(LocationSetting(kind: .approximate, region: mapo).origin, mapo.coordinate, "아직 위치를 못 받았으면 동네로")
        XCTAssertNil(LocationSetting(kind: .none, region: mapo).origin)
        XCTAssertEqual(Set(Regions.all.map(\.name)).count, Regions.all.count)
        XCTAssertEqual(Regions.seoul.count, 25)
    }
}

final class ProfileTests: XCTestCase {
    func testScoresFollowReasons() {
        let cafe = experiment("cafe", .breath, [.quiet, .solo, .novel])
        let party = experiment("party", .connection, [.together, .novel])
        let profile = TasteProfile(journal: journal([(cafe, .liked, [.quiet]), (party, .disliked, [.together])]))
        XCTAssertEqual(profile.tagScores[.quiet], 3)
        XCTAssertEqual(profile.tagScores[.solo], 1)
        XCTAssertEqual(profile.tagScores[.novel], 0)
        XCTAssertEqual(profile.tagScores[.together], -3)
        XCTAssertEqual(profile.topTags(), [.quiet, .solo])
        XCTAssertEqual(profile.dislikedTags, [.together])
        XCTAssertEqual(profile.likedDomains, [.breath])
        XCTAssertTrue(profile.hasDislikedTag(party))
    }

    func testDomainStates() {
        XCTAssertEqual(DomainStat().state, .unexplored)
        XCTAssertEqual(DomainStat(tried: 1, liked: 0).state, .exploring)
        XCTAssertEqual(DomainStat(tried: 3, liked: 2, disliked: 1).state, .favorite)
        XCTAssertEqual(DomainStat(tried: 2, liked: 0, disliked: 2).state, .notForMe)
    }
}

final class StampTests: XCTestCase {
    func testStampsAndGold() {
        let walk = experiment("walk", .nature, [.outdoors])
        var history = journal([(walk, .liked, []), (walk, .liked, [])])
        let before = history
        XCTAssertEqual(Stamps.board(history).first { $0.domain == .nature }?.isGold, false)
        history.record(Entry(experiment: walk, feeling: .liked, why: [], at: monday))
        history.record(Entry(experiment: experiment("tea", .food, [.sensory]), feeling: .meh, why: [], at: monday))
        let board = Stamps.board(history)
        XCTAssertEqual(board.count, 8)
        XCTAssertEqual(board.filter(\.earned).map(\.domain), [.food, .nature])
        XCTAssertTrue(board.first { $0.domain == .nature }!.isGold)
        XCTAssertEqual(Stamps.newlyEarned(before: before, after: history).map(\.domain), [.food, .nature], "새 우표 하나, 금색 하나")
    }
}

final class InsightTests: XCTestCase {
    func testNeedsAFewEntries() {
        let cafe = experiment("cafe", .breath, [.quiet])
        XCTAssertNil(Insight.summarize(journal(Array(repeating: (cafe, .liked, [.quiet]), count: 4))))
    }

    func testFindsTheCommonReasonAcrossDomains() throws {
        let items: [(Experiment, Feeling, [Tag])] = [
            (experiment("nap", .rest, [.quiet, .solo]), .liked, [.quiet]),
            (experiment("album", .senses, [.quiet, .slow]), .liked, [.quiet]),
            (experiment("poem", .breath, [.quiet, .slow]), .liked, [.quiet, .slow]),
            (experiment("party", .connection, [.together, .novel]), .disliked, [.together]),
            (experiment("run", .movement, [.moving]), .meh, []),
        ]
        let summary = try XCTUnwrap(Insight.summarize(journal(items)))
        XCTAssertEqual(summary.headline, "조용한 것에 마음이 가는 사람")
        XCTAssertTrue(summary.lines.contains("잠과 쉼, 숨과 마음, 감각처럼 분야는 달라도 ‘조용해서’가 공통점이에요."))
        XCTAssertTrue(summary.lines.contains("‘함께라서’는 아직 잘 안 맞았어요. 별로인 걸 아는 것도 취향이에요."))
        XCTAssertEqual(summary.nextFrontier, .food)
    }
}

final class RecommenderTests: XCTestCase {
    private let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, checkIn: anything)

    func testFirstWeekSpreadsAcrossDomains() {
        var rng = SeededRandom(seed: 1)
        let picks = recommender.weeklyPicks(journal: Journal(), now: monday, using: &rng)
        XCTAssertEqual(picks.count, 3)
        XCTAssertEqual(Set(picks.map(\.experiment.domain)).count, 3)
        XCTAssertTrue(picks.allSatisfy { $0.slot == .fresh })
        XCTAssertEqual(picks[0].reason, "첫 실험은 여러 구역에서 하나씩 골랐어요")
    }

    func testMixesConfirmSideStepAndFresh() {
        let history = journal([(card("breath-library"), .liked, [.quiet]), (card("breath-poem"), .liked, [.quiet])])
        for seed in 0..<50 {
            var rng = SeededRandom(seed: UInt64(seed))
            let picks = recommender.weeklyPicks(journal: history, now: monday, using: &rng)
            XCTAssertEqual(picks.map(\.slot), [.confirm, .sideStep, .fresh])
            XCTAssertEqual(Set(picks.map(\.experiment.domain)).count, 3, "세 장은 모두 다른 구역")
            XCTAssertFalse(picks.contains { history.hasTried($0.id) })
            XCTAssertNotEqual(picks[1].experiment.domain, .breath, "옆으로 한 칸은 익숙한 구역이 아니다")
            XCTAssertTrue(picks[1].experiment.tags.contains(where: [.quiet, .solo, .slow].contains))
            XCTAssertTrue(picks[2].reason.hasPrefix("아직 우표가 없는"), picks[2].reason)
        }
    }

    func testEveryPickFitsTheCheckIn() {
        let checkIn = CheckIn(budget: .free, energy: .low, time: .short, company: .solo)
        let strict = Recommender(catalog: Catalog.all + SampleOffers.all, allowSponsored: true, checkIn: checkIn)
        var history = Journal()
        var rng = SeededRandom(seed: 9)
        for week in 0..<4 {
            let now = monday.addingTimeInterval(Double(week) * 7 * day)
            let picks = strict.weeklyPicks(journal: history, now: now, using: &rng)
            XCTAssertEqual(picks.count, 3)
            for pick in picks {
                XCTAssertTrue(checkIn.allows(pick.experiment, travelMinutes: pick.travelMinutes), pick.id)
                XCTAssertEqual(pick.experiment.effectiveCost, 0)
            }
            history.markShown(picks.map(\.id), at: now)
        }
    }

    /// 매주 실험을 받기만 하고 하지 않아도, 석 주 안에는 같은 카드가 다시 나오지 않는다.
    func testEveryWeekBringsSomethingNew() {
        let standard = Recommender(catalog: Catalog.all, allowSponsored: false)
        var history = Journal()
        var seen = Set<String>()
        var rng = SeededRandom(seed: 7)
        for week in 0..<3 {
            let now = monday.addingTimeInterval(Double(week) * 7 * day)
            let picks = standard.weeklyPicks(journal: history, now: now, using: &rng)
            XCTAssertEqual(picks.count, 3)
            for pick in picks {
                XCTAssertFalse(seen.contains(pick.id), "\(pick.id)가 \(week)주차에 또 나왔다")
                seen.insert(pick.id)
            }
            history.markShown(picks.map(\.id), at: now)
        }
    }

    func testSwapCanAskForCheaperOrShorter() throws {
        let expensive = card("making-pottery")
        var rng = SeededRandom(seed: 4)
        for _ in 0..<20 {
            let cheaper = try XCTUnwrap(recommender.pick(
                slot: .fresh, journal: Journal(), now: monday, excluding: [expensive.id], avoidDomains: [],
                sponsorAllowed: false, where: { $0.effectiveCost < expensive.effectiveCost }, using: &rng
            ))
            XCTAssertLessThan(cheaper.experiment.effectiveCost, expensive.effectiveCost)
            let shorter = try XCTUnwrap(recommender.pick(
                slot: .fresh, journal: Journal(), now: monday, excluding: [expensive.id], avoidDomains: [],
                sponsorAllowed: false, where: { $0.minutes < 30 }, using: &rng
            ))
            XCTAssertLessThan(shorter.experiment.minutes, 30)
        }
    }

    func testTogetherWeeksLeanTowardCompany() {
        let history = journal([(card("breath-poem"), .liked, [.slow]), (card("rest-no-alarm"), .liked, [.slow])])
        func hits(_ company: CheckIn.Company) -> Int {
            let checkIn = CheckIn(budget: .any, energy: .high, time: .fullDay, company: company)
            let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, checkIn: checkIn)
            return (0..<100).reduce(0) { total, seed in
                var rng = SeededRandom(seed: UInt64(seed))
                return total + recommender.weeklyPicks(journal: history, now: monday, using: &rng)
                    .filter { $0.experiment.tags.contains(.together) }.count
            }
        }
        XCTAssertGreaterThan(hits(.together), hits(.solo) * 2)
    }

    func testSkippedCardsRestForAMonth() {
        let two = Recommender(catalog: [experiment("a", .rest, [.quiet]), experiment("b", .rest, [.quiet])], allowSponsored: false)
        var history = Journal()
        history.skip("a", at: monday)
        var rng = SeededRandom(seed: 3)
        XCTAssertEqual(two.weeklyPicks(journal: history, now: monday + day, count: 2, using: &rng).map(\.id), ["b"])
        XCTAssertEqual(Set(two.weeklyPicks(journal: history, now: monday + 31 * day, count: 2, using: &rng).map(\.id)), ["a", "b"])
    }
}

final class SponsoredTests: XCTestCase {
    private let history = journal([
        (experiment("craft", .making, [.quiet, .making]), .liked, [.quiet, .making]),
        (experiment("lib", .breath, [.quiet, .novel]), .liked, [.quiet]),
        (experiment("party", .connection, [.together]), .disliked, [.together]),
    ])

    func testAtMostOneAdNeverInConfirmAndNeverAgainstTaste() {
        let ads = [
            experiment("ad-craft", .nature, [.making, .quiet], sponsor: Sponsorship(brand: "A", benefit: "x", priceAfterBenefit: 0)),
            experiment("ad-tea", .food, [.quiet, .sensory], sponsor: Sponsorship(brand: "B", benefit: "y", priceAfterBenefit: 0)),
            experiment("ad-club", .senses, [.together, .quiet], sponsor: Sponsorship(brand: "C", benefit: "z", priceAfterBenefit: 0)),
        ]
        let recommender = Recommender(catalog: Catalog.all + ads, allowSponsored: true, checkIn: anything)
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
        XCTAssertGreaterThan(adSeen, 0)
    }

    /// 제휴처는 그 주 시간 안에 오갈 수 있는 사람에게만 보인다.
    func testVenueAdsNeedLocationAndTime() {
        let yoga = SampleOffers.sponsored.first { $0.id == "ad-sample-yoga" }!
        let mapo = Regions.all.first { $0.name == "서울 마포구" }!
        let busan = Regions.all.first { $0.name == "부산" }!
        func reach(_ location: LocationSetting, _ time: CheckIn.TimeBudget) -> Bool {
            Recommender(catalog: [yoga], allowSponsored: true, checkIn: CheckIn(budget: .any, energy: .high, time: time, company: .solo), location: location).fits(yoga)
        }
        XCTAssertFalse(reach(.none, .fullDay), "위치 없이")
        XCTAssertTrue(reach(LocationSetting(kind: .neighborhood, region: mapo), .halfDay))
        XCTAssertFalse(reach(LocationSetting(kind: .neighborhood, region: mapo), .short))
        XCTAssertFalse(reach(LocationSetting(kind: .neighborhood, region: busan, mode: .car), .fullDay), "부산에서 마포 요가는 너무 멀다")
    }

    func testAdsCanBeTurnedOffAndExpire() {
        let ad = experiment("ad", .making, [.making, .quiet], sponsor: Sponsorship(brand: "A", benefit: "x", priceAfterBenefit: 0, endsAt: monday + day))
        let off = Recommender(catalog: Catalog.all + [ad], allowSponsored: false, checkIn: anything)
        let on = Recommender(catalog: Catalog.all + [ad], allowSponsored: true, checkIn: anything)
        for seed in 0..<100 {
            var rng = SeededRandom(seed: UInt64(seed))
            XCTAssertFalse(off.weeklyPicks(journal: history, now: monday, using: &rng).contains { $0.experiment.isSponsored })
            XCTAssertFalse(on.weeklyPicks(journal: history, now: monday + 2 * day, using: &rng).contains { $0.experiment.isSponsored })
        }
    }

    func testWeekendKitsStayInsideTheBudget() {
        let free = Recommender(catalog: Catalog.all + SampleOffers.all, allowSponsored: true, checkIn: CheckIn(budget: .free, energy: .low, time: .short, company: .solo))
        XCTAssertTrue(free.weekendIdeas(journal: history, now: monday).isEmpty, "예산 0원이면 키트는 안 보인다")
        let twenty = Recommender(catalog: Catalog.all + SampleOffers.all, allowSponsored: true, checkIn: CheckIn(budget: .under30k, energy: .low, time: .short, company: .solo))
        let ideas = twenty.weekendIdeas(journal: history, now: monday)
        XCTAssertFalse(ideas.isEmpty, "주말은 시간·에너지를 따지지 않는다")
        XCTAssertTrue(ideas.allSatisfy { ($0.kit?.price ?? 0) <= 30_000 })
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
}

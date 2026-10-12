import XCTest
@testable import TasteCore

private let day: TimeInterval = 86_400
private let mapo = Coordinate(latitude: 37.5663, longitude: 126.9019)

private var utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

/// 2026-10-12 (월) 09:00 UTC
private let monday = date(2026, 10, 12)

private func card(_ id: String) -> Experiment {
    Catalog.all.first { $0.id == id }!
}

final class SeasonTests: XCTestCase {
    func testSeasonsAndSeasonalCards() {
        XCTAssertEqual(Season(month: 3), .spring)
        XCTAssertEqual(Season(month: 8), .summer)
        XCTAssertEqual(Season(month: 11), .autumn)
        XCTAssertEqual(Season(month: 1), .winter)
        for season in Season.allCases {
            XCTAssertGreaterThanOrEqual(Catalog.all.filter { $0.seasons?.contains(season) ?? false }.count, 3, season.title)
        }
        XCTAssertTrue(card("nature-blossom").isInSeason(at: date(2026, 4, 5), calendar: utc))
        XCTAssertFalse(card("nature-blossom").isInSeason(at: monday, calendar: utc))
        XCTAssertTrue(card("breath-4-6").isInSeason(at: monday, calendar: utc))
    }

    /// 계절마다, 체크인을 어떻게 고르든 실험이 바닥나지 않는다(지도 확인 전, 위치 없이도).
    func testEnoughCardsEverySeason() {
        for month in [1, 4, 7, 10] {
            let now = date(2026, month, 15)
            for budget in CheckIn.Budget.allCases {
                for energy in CheckIn.Energy.allCases {
                    for time in CheckIn.TimeBudget.allCases {
                        let checkIn = CheckIn(budget: budget, energy: energy, time: time, company: .solo)
                        let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, checkIn: checkIn, calendar: utc)
                        let fitting = Catalog.all.filter { recommender.fits($0) && $0.isInSeason(at: now, calendar: utc) }
                        XCTAssertGreaterThanOrEqual(fitting.count, 12, "\(month)월 \(budget) \(energy) \(time)")
                        XCTAssertGreaterThanOrEqual(Set(fitting.map(\.domain)).count, 4, "\(month)월 \(budget) \(energy) \(time)")
                    }
                }
            }
        }
    }

    func testOutOfSeasonCardsNeverShow() {
        let blossom = card("nature-blossom")
        let anything = CheckIn(budget: .any, energy: .high, time: .fullDay, company: .together)
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: [.park: [Venue(name: "공원", coordinate: mapo)]])
        let location = LocationSetting(kind: .neighborhood, region: Region(name: "마포", coordinate: mapo))
        let recommender = Recommender(catalog: [blossom], allowSponsored: false, checkIn: anything, location: location, nearby: found, calendar: utc)
        var rng = SeededRandom(seed: 1)
        XCTAssertTrue(recommender.weeklyPicks(journal: Journal(), now: monday, using: &rng).isEmpty)
        XCTAssertEqual(recommender.weeklyPicks(journal: Journal(), now: date(2026, 4, 6), using: &rng).map(\.id), [blossom.id])
    }
}

final class WeatherTests: XCTestCase {
    private func outlook(rain: [Double], high: Double = 20) -> WeatherOutlook {
        let start = utc.startOfDay(for: monday)
        return WeatherOutlook(origin: mapo, fetchedAt: monday, days: rain.enumerated().map { index, chance in
            DayForecast(date: start + Double(index) * day, rainChance: chance, highC: high)
        })
    }

    func testGoodDaysAndNote() {
        let mixed = outlook(rain: [0.9, 0.1, 0.8, 0.2, 0.7, 0.1, 0.9])
        XCTAssertEqual(mixed.goodDays(from: monday, calendar: utc).count, 3)
        XCTAssertFalse(mixed.isRoughWeek(from: monday, calendar: utc))
        XCTAssertEqual(mixed.outdoorNote(from: monday, calendar: utc), "바깥에 나가기 좋은 날: 화·목·토")
        let rainy = outlook(rain: [0.9, 0.9, 0.8, 0.9, 0.7, 0.1, 0.9])
        XCTAssertTrue(rainy.isRoughWeek(from: monday, calendar: utc))
        XCTAssertTrue(outlook(rain: Array(repeating: 0, count: 7), high: 35).isRoughWeek(from: monday, calendar: utc), "폭염")
        XCTAssertTrue(outlook(rain: Array(repeating: 0, count: 7), high: -3).isRoughWeek(from: monday, calendar: utc), "한파")
        XCTAssertTrue(mixed.isFresh(for: mapo, now: monday + 3_600))
        XCTAssertFalse(mixed.isFresh(for: mapo, now: monday + day))
    }

    /// 궂은 주에는 실내 실험을 먼저, 바깥 실험에는 좋은 날을 적어 준다.
    func testRoughWeekPrefersIndoors() {
        let anything = CheckIn(budget: .any, energy: .high, time: .fullDay, company: .solo)
        let rainy = outlook(rain: Array(repeating: 0.9, count: 7))
        let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, checkIn: anything, weather: rainy, calendar: utc)
        for seed in 0..<30 {
            var rng = SeededRandom(seed: UInt64(seed))
            let picks = recommender.weeklyPicks(journal: Journal(), now: monday, using: &rng)
            XCTAssertEqual(picks.count, 3)
            XCTAssertFalse(picks.contains(where: \.experiment.isOutdoor), "실내 실험이 충분하면 바깥 실험은 안 나온다")
        }
        let sunny = Recommender(catalog: [card("nature-clouds")], allowSponsored: false, checkIn: anything, weather: outlook(rain: [0.1, 0.1, 0.9, 0.9, 0.9, 0.9, 0.9]), calendar: utc)
        var rng = SeededRandom(seed: 1)
        XCTAssertEqual(sunny.weeklyPicks(journal: Journal(), now: monday, using: &rng).first?.weatherNote, "바깥에 나가기 좋은 날: 월·화")
    }
}

final class ReminderTests: XCTestCase {
    func testWeeklyReminders() {
        let wednesday = date(2026, 10, 14, 8)
        XCTAssertEqual(WeeklyReminders.plan(now: wednesday, weekendPlan: nil, calendar: utc).map(\.id), ["checkin"])
        XCTAssertEqual(WeeklyReminders.plan(now: wednesday, weekendPlan: nil, calendar: utc).first?.date, date(2026, 10, 19, 9), "다음 월요일 아침")

        let kitPlan = SampleOffers.kits.first { $0.kit?.leadDays == 2 }!
        let reminders = WeeklyReminders.plan(now: wednesday, weekendPlan: kitPlan, calendar: utc)
        XCTAssertEqual(reminders.map(\.id), ["checkin", "kit-deadline", "weekend-plan"])
        XCTAssertEqual(reminders[1].date, date(2026, 10, 15, 9), "목요일 마감 3시간 전")
        XCTAssertEqual(reminders[2].date, date(2026, 10, 17, 10), "토요일 아침")

        let afterDeadline = WeeklyReminders.plan(now: date(2026, 10, 15, 13), weekendPlan: kitPlan, calendar: utc)
        XCTAssertFalse(afterDeadline.contains { $0.id == "kit-deadline" }, "마감이 지나면 알리지 않는다")
        let homePlan = card("making-letter")
        XCTAssertEqual(WeeklyReminders.plan(now: wednesday, weekendPlan: homePlan, calendar: utc).map(\.id), ["checkin", "weekend-plan"])
    }
}

final class WeeklyReportTests: XCTestCase {
    func testCountsOnlyThatWeekAndNothingPersonal() throws {
        var journal = Journal()
        let tea = card("food-tea-blind")
        journal.record(Entry(experiment: tea, feeling: .liked, why: [.quiet], note: "비밀 메모", photo: "a.jpg", at: monday))
        journal.record(Entry(experiment: card("making-letter"), feeling: .meh, why: [], at: monday + day))
        journal.record(Entry(experiment: card("breath-poem"), feeling: .liked, why: [], at: monday - 7 * day))
        journal.recordSwap(.tooExpensive, at: monday)
        journal.recordSwap(nil, at: monday)
        journal.recordCodeCopy(at: monday)
        let report = WeeklyReport.make(week: Week.key(monday, calendar: utc), journal: journal, checkedIn: true, calendar: utc)
        XCTAssertEqual(report.postcards, 2)
        XCTAssertEqual(report.withPhoto, 1)
        XCTAssertEqual(report.liked, 1)
        XCTAssertEqual(report.swapsTooExpensive, 1)
        XCTAssertEqual(report.swapsOther, 1)
        XCTAssertEqual(report.adCodeCopies, 1)

        let data = try JSONEncoder().encode(report)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["week", "checkedIn", "postcards", "withPhoto", "liked", "swapsTooExpensive", "swapsNoTime", "swapsOther", "adCodeCopies"])
        let json = String(decoding: data, as: UTF8.self)
        for secret in ["비밀", "a.jpg", tea.id, "quiet"] {
            XCTAssertFalse(json.contains(secret), "\(secret) leaked")
        }
    }

    func testOldJournalStillDecodes() throws {
        let old = #"{"entries":[],"shown":{},"skipped":{}}"#.data(using: .utf8)!
        let journal = try JSONDecoder().decode(Journal.self, from: old)
        XCTAssertTrue(journal.swaps.isEmpty)
        XCTAssertTrue(journal.codeCopies.isEmpty)
    }
}

final class BlockedVenueTests: XCTestCase {
    /// "문 닫혀 있었어요"라고 알려 준 곳은 다시 권하지 않는다.
    func testBlockedVenuesAreSkipped() {
        let closed = Venue(name: "닫힌 사우나", coordinate: Coordinate(latitude: 37.567, longitude: 126.91))
        let open = Venue(name: "열린 사우나", coordinate: Coordinate(latitude: 37.57, longitude: 126.92))
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: [.sauna: [closed, open]])
        XCTAssertEqual(found.nearest(.sauna, from: mapo)?.name, "닫힌 사우나")
        let filtered = found.excluding([NearbyPlaces.blockKey(closed)])
        XCTAssertEqual(filtered.nearest(.sauna, from: mapo)?.name, "열린 사우나")
        XCTAssertEqual(filtered.excluding([NearbyPlaces.blockKey(open)]).venues(for: .sauna), [])
    }
}

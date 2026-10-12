import XCTest
@testable import TasteCore

private let day: TimeInterval = 86_400

private var utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
}

private let monday = date(2026, 10, 12)

private func card(_ id: String) -> Experiment {
    Catalog.all.first { $0.id == id }!
}

final class InviteTests: XCTestCase {
    func testRoundTripAndSanitizing() throws {
        let invite = Invite(experimentID: "breath-poem", from: "  지수와 함께하는 아주 긴 이름입니다  ")
        XCTAssertLessThanOrEqual(invite.from?.count ?? 0, Invite.maxNameLength)
        XCTAssertEqual(invite.from, "지수와 함께하는 아주", "자른 뒤 끝 공백은 없다")
        let parsed = try XCTUnwrap(Invite(url: invite.url))
        XCTAssertEqual(parsed, invite)
        XCTAssertEqual(parsed.experiment(in: Catalog.all)?.title, "시 세 편 읽기")
        XCTAssertTrue(invite.message(for: card("breath-poem")).contains("tastepostcard://invite?e=breath-poem"))
        XCTAssertEqual(Invite(experimentID: "x", from: " ").senderName, "친구")
    }

    func testRejectsStrangeLinks() {
        XCTAssertNil(Invite(url: URL(string: "https://example.com/invite?e=a")!))
        XCTAssertNil(Invite(url: URL(string: "tastepostcard://other?e=a")!))
        XCTAssertNil(Invite(url: URL(string: "tastepostcard://invite")!))
        XCTAssertNil(Invite(url: URL(string: "tastepostcard://invite?e=../../etc")!))
    }
}

final class PrintPackTests: XCTestCase {
    func testSeasonKeysAndSuggestion() {
        XCTAssertEqual(SeasonKey(date(2027, 1, 10), calendar: utc), SeasonKey(year: 2026, season: .winter), "1월은 지난해 겨울")
        XCTAssertEqual(SeasonKey(date(2026, 12, 10), calendar: utc).title, "2026 겨울")
        var entries: [Entry] = []
        for index in 0..<10 {
            entries.append(Entry(experiment: card("breath-poem"), feeling: index % 2 == 0 ? .liked : .meh, why: [], photo: index < 3 ? "p\(index).jpg" : nil, at: date(2026, 9, 1 + index)))
        }
        entries.append(Entry(experiment: card("breath-poem"), feeling: .liked, why: [], at: date(2026, 6, 1)))
        let seasons = PrintPack.seasons(entries, calendar: utc)
        XCTAssertEqual(seasons.map(\.key.title), ["2026 가을", "2026 여름"])
        XCTAssertEqual(seasons.first?.count, 10)
        let pack = PrintPack.suggest(entries, for: SeasonKey(year: 2026, season: .autumn), calendar: utc)
        XCTAssertEqual(pack.count, PrintPack.size)
        XCTAssertEqual(pack.filter { $0.photo != nil }.count, 3, "사진 있는 엽서는 다 들어간다")
        XCTAssertEqual(pack.map(\.at), pack.map(\.at).sorted(), "날짜 순서로 인쇄")
    }
}

final class SwapLearningTests: XCTestCase {
    func testLearnsFromReasons() {
        var journal = Journal()
        XCTAssertFalse(SwapLearning(journal: journal, now: monday).costSensitive)
        journal.recordSwap(.tooExpensive, at: monday - day)
        journal.recordSwap(.tooExpensive, at: monday - 2 * day)
        for _ in 0..<3 { journal.recordSwap(.notFeelingIt, domain: .connection, at: monday - day) }
        journal.recordSwap(.noTime, at: monday - 40 * day)
        let learning = SwapLearning(journal: journal, now: monday)
        XCTAssertTrue(learning.costSensitive)
        XCTAssertFalse(learning.timeSensitive, "4주보다 오래된 건 보지 않는다")
        XCTAssertEqual(learning.coolDomains, [.connection])
        XCTAssertGreaterThan(learning.penalty(card("making-pottery"), travelMinutes: 60), learning.penalty(card("breath-4-6"), travelMinutes: 0))
    }

    func testSuggestsShorterTimeAfterRepeatedNoTime() {
        var journal = Journal()
        for offset in 1...3 { journal.recordSwap(.noTime, at: monday - Double(offset) * day) }
        let learning = SwapLearning(journal: journal, now: monday)
        XCTAssertEqual(learning.suggestion(for: .standard)?.time, .short)
        XCTAssertNil(learning.suggestion(for: CheckIn(budget: .free, energy: .low, time: .short, company: .solo)))
    }

    /// 돈 때문에 자주 바꾼 사람에게는 같은 예산 안에서도 싼 실험이 먼저 온다.
    func testCostSensitivityShiftsPicks() {
        let anything = CheckIn(budget: .any, energy: .high, time: .fullDay, company: .solo)
        let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, checkIn: anything, calendar: utc)
        var sensitive = Journal()
        sensitive.recordSwap(.tooExpensive, at: monday - day)
        sensitive.recordSwap(.tooExpensive, at: monday - day)
        func averageCost(_ journal: Journal) -> Double {
            var total = 0, count = 0
            for seed in 0..<60 {
                var rng = SeededRandom(seed: UInt64(seed))
                for pick in recommender.weeklyPicks(journal: journal, now: monday, using: &rng) {
                    total += pick.experiment.effectiveCost
                    count += 1
                }
            }
            return Double(total) / Double(max(count, 1))
        }
        XCTAssertLessThan(averageCost(sensitive), averageCost(Journal()))
    }
}

final class OfferValidatorTests: XCTestCase {
    private func templateURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("partners/offer-template.json")
    }

    func testTemplateIsValidAndBecomesExperiments() throws {
        let file = try JSONDecoder().decode(OfferFile.self, from: Data(contentsOf: templateURL()))
        let issues = OfferValidator.validate(file, now: monday, calendar: utc)
        XCTAssertFalse(issues.contains { $0.level == .error }, issues.description)
        let experiments = OfferValidator.experiments(from: file, now: monday, calendar: utc)
        XCTAssertEqual(experiments.map(\.id), ["ad-first-yoga", "kit-home-tea"])
        let yoga = experiments[0]
        XCTAssertEqual(yoga.sponsor?.brand, "예시 요가 스튜디오")
        XCTAssertEqual(yoga.effectiveCost, 0)
        XCTAssertEqual(yoga.domain, .movement)
        if case .venue(let venue) = yoga.place { XCTAssertEqual(venue.coordinate.latitude, 37.556) } else { XCTFail() }
        XCTAssertEqual(experiments[1].kit?.leadDays, 2)
        XCTAssertTrue(experiments[1].place.isHome)
    }

    func testCatchesMistakes() throws {
        var file = try JSONDecoder().decode(OfferFile.self, from: Data(contentsOf: templateURL()))
        file.offers[0].detail = "면역력을 높이고 질병을 예방해요"
        file.offers[0].place?.latitude = 126.9
        file.offers[0].priceAfterBenefit = 30_000
        file.offers[0].code = "free"
        file.offers[0].tags = ["moving", "spicy"]
        file.offers[0].endsAt = "2026-01-01"
        file.offers[1].kit?.leadDays = 10
        let messages = OfferValidator.validate(file, now: monday, calendar: utc).filter { $0.level == .error }.map(\.message)
        XCTAssertTrue(messages.contains { $0.contains("면역력") })
        XCTAssertTrue(messages.contains { $0.contains("한국 밖") })
        XCTAssertTrue(messages.contains { $0.contains("더 비싸") || $0.contains("비싸요") })
        XCTAssertTrue(messages.contains { $0.contains("혜택 코드") })
        XCTAssertTrue(messages.contains { $0.contains("spicy") })
        XCTAssertTrue(messages.contains { $0.contains("끝난") })
        XCTAssertTrue(messages.contains { $0.contains("배송일") })
        XCTAssertTrue(OfferValidator.experiments(from: file, now: monday, calendar: utc).isEmpty, "오류 있는 제안은 앱에 안 올라간다")
    }

    func testRedemptionSummary() {
        let csv = "date,code\n2026-10-12,YOGAFREE\n2026-10-13,yogafree\n2026-10-20,YOGAFREE\n2026-10-14,TEA40\n이상한 줄\n"
        let summary = RedemptionReport.summarize(csv: csv, calendar: utc)
        XCTAssertEqual(summary.rows, [
            .init(code: "TEA40", week: "2026-W42", count: 1),
            .init(code: "YOGAFREE", week: "2026-W42", count: 2),
            .init(code: "YOGAFREE", week: "2026-W43", count: 1),
        ])
        XCTAssertEqual(summary.skipped, 1)
    }
}

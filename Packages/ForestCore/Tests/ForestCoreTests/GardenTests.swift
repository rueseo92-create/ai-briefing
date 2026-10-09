import XCTest
@testable import ForestCore

final class GardenTests: XCTestCase {
    func testStartsWithFreeItemsOnly() {
        let garden = GardenCollection()
        XCTAssertEqual(garden.unlocked, [.leafSpring, .skyDay])
        XCTAssertTrue(garden.unseen.isEmpty)
        XCTAssertEqual(garden.style.leaf, .leafSpring)
        XCTAssertEqual(garden.style.sky, .skyDay)
        XCTAssertTrue(garden.style.decorations.isEmpty)
    }

    func testUnlocksFromDaysUrgesAndCheers() {
        var garden = GardenCollection()
        XCTAssertEqual(garden.update(with: GardenProgress(cleanDays: 7, urgeWins: 0, cheers: 0)),
                       [.leafMaple, .daisy, .pebble, .mushroom])
        XCTAssertEqual(garden.update(with: GardenProgress(cleanDays: 7, urgeWins: 1, cheers: 3)),
                       [.butterfly, .ladybug])
        XCTAssertEqual(garden.update(with: GardenProgress(cleanDays: 7, urgeWins: 1, cheers: 3)), [])
        XCTAssertEqual(garden.unseen, [.leafMaple, .daisy, .pebble, .butterfly, .mushroom, .ladybug])
        garden.markSeen()
        XCTAssertTrue(garden.unseen.isEmpty)
    }

    /// 다시 해서 참은 날이 하루 빠져도, 한 번 생긴 장식은 그대로다.
    func testUnlocksNeverDisappear() {
        var garden = GardenCollection()
        _ = garden.update(with: GardenProgress(cleanDays: 7, urgeWins: 0, cheers: 0))
        _ = garden.update(with: GardenProgress(cleanDays: 6, urgeWins: 0, cheers: 0))
        XCTAssertTrue(garden.unlocked.contains(.mushroom))
        XCTAssertTrue(garden.toggle(.mushroom))
    }

    func testToggleRules() {
        var garden = GardenCollection()
        XCTAssertFalse(garden.toggle(.deer), "아직 없는 장식은 달 수 없다")
        _ = garden.update(with: GardenProgress(cleanDays: 400, urgeWins: 100, cheers: 100))
        XCTAssertEqual(garden.unlocked.count, GardenItem.allCases.count)

        XCTAssertTrue(garden.toggle(.leafCherry))
        XCTAssertEqual(garden.style.leaf, .leafCherry)
        XCTAssertTrue(garden.toggle(.skyNight))
        XCTAssertEqual(garden.style.sky, .skyNight)

        let decorations = GardenItem.items(in: .decoration)
        for item in decorations.prefix(GardenStyle.maxDecorations) {
            XCTAssertTrue(garden.toggle(item))
        }
        XCTAssertFalse(garden.toggle(decorations[GardenStyle.maxDecorations]), "장식이 꽉 찼다")
        XCTAssertTrue(garden.toggle(decorations[0]))
        XCTAssertFalse(garden.style.isUsing(decorations[0]))
        XCTAssertTrue(garden.toggle(decorations[GardenStyle.maxDecorations]))
        XCTAssertEqual(garden.style.decorations.count, GardenStyle.maxDecorations)
    }

    func testEveryCategoryHasAFreeItemAndHintsReadWell() {
        for category in GardenCategory.allCases where category != .decoration {
            XCTAssertTrue(GardenItem.items(in: category).contains { $0.unlock == .free })
        }
        XCTAssertEqual(GardenItem.mushroom.unlock.hint, "7일 참으면")
        XCTAssertEqual(GardenItem.firefly.unlock.hint, "참기를 5번 버티면")
        XCTAssertEqual(GardenItem.bird.unlock.hint, "물을 10방울 받으면")
    }

    func testSavedGardenRoundTrips() throws {
        var garden = GardenCollection()
        _ = garden.update(with: GardenProgress(cleanDays: 30, urgeWins: 5, cheers: 0))
        garden.toggle(.nest)
        garden.toggle(.leafGinkgo)
        let restored = try JSONDecoder().decode(GardenCollection.self, from: JSONEncoder().encode(garden))
        XCTAssertEqual(restored, garden)
    }

    func testInboxCountsLifetimeCheersAndOldDataDecodes() throws {
        let day: TimeInterval = 86_400
        let t0 = Date(timeIntervalSince1970: 1_790_000_000)
        var inbox = CheerInbox(now: t0)
        _ = inbox.receive([IncomingCheer(sender: "a", sentAt: t0), IncomingCheer(sender: "b", sentAt: t0)], now: t0)
        _ = inbox.receive([IncomingCheer(sender: "a", sentAt: t0 + day)], now: t0 + day)
        XCTAssertEqual(inbox.total, 3)

        let old = #"{"day":"2026-10-08","count":2,"senders":["x"]}"#.data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(CheerInbox.self, from: old).total, 2)
    }
}

final class PublicGardenTests: XCTestCase {
    /// 다른 기기에서 온 이상한 값은 걸러서 그린다.
    func testForestStyleIsSanitized() {
        let tree = PublicTree(
            id: "x", name: "x", stage: .tree, isWilting: false, urgingSince: nil, startDay: "2026-10-01",
            updatedAt: Date(), leaf: .skyNight,
            decorations: [.deer, .deer, .leafMaple, .daisy, .pebble, .mushroom, .rabbit, .owl, .nest]
        )
        XCTAssertEqual(tree.style.leaf, .leafSpring)
        XCTAssertEqual(tree.style.decorations, [.deer, .daisy, .pebble, .mushroom, .rabbit])
    }

    func testOldTreesWithoutStyleLookPlain() {
        let tree = PublicTree(id: "x", name: "x", stage: .seed, isWilting: false, urgingSince: nil, startDay: "d", updatedAt: Date())
        XCTAssertEqual(tree.style, GardenStyle())
    }
}

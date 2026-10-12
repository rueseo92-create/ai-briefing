import XCTest
@testable import TasteCore

private let mapo = Coordinate(latitude: 37.5663, longitude: 126.9019)
private let monday = Date(timeIntervalSince1970: 1_791_795_600)

/// 마포구청에서 동쪽으로 km만큼 떨어진 점(대략).
private func east(_ km: Double) -> Coordinate {
    Coordinate(latitude: mapo.latitude, longitude: mapo.longitude + km / 88.2)
}

private func venue(_ name: String, _ km: Double) -> Venue {
    Venue(name: name, coordinate: east(km))
}

final class PlacesTests: XCTestCase {
    func testEveryNeedCanBeSearched() {
        for need in PlaceNeed.allCases {
            XCTAssertFalse(need.queries.isEmpty, need.title)
            XCTAssertGreaterThan(need.radiusKm, 0)
        }
        let needs = Catalog.all.compactMap { experiment -> PlaceNeed? in
            if case .find(let need) = experiment.place { return need }
            return nil
        }
        XCTAssertGreaterThanOrEqual(needs.count, 25, "장소가 필요한 카드는 지도에서 확인한다")
    }

    func testNearbyKeepsCloseDistinctPlaces() {
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: [
            .waterside: [venue("망원한강공원", 3), venue("망원한강공원", 3.05), venue("먼 강", 20), venue("가까운 천", 1)],
            .park: (1...8).map { venue("공원\($0)", Double($0) * 0.5) },
        ])
        XCTAssertEqual(found.venues(for: .waterside).map(\.name), ["가까운 천", "망원한강공원"], "범위 밖과 같은 곳은 뺀다")
        XCTAssertEqual(found.venues(for: .park).count, NearbyPlaces.maxPerNeed)
        XCTAssertEqual(found.nearest(.park, from: mapo)?.name, "공원1")
        XCTAssertTrue(found.missing.contains(.campfire))
        XCTAssertFalse(found.missing.contains(.park))
    }

    func testRefreshWhenMovedOrOld() {
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: [:])
        XCTAssertTrue(found.isFresh(for: east(0.5), now: monday + 86_400))
        XCTAssertFalse(found.isFresh(for: east(3), now: monday), "동네가 바뀌면 다시 찾는다")
        XCTAssertFalse(found.isFresh(for: mapo, now: monday + NearbyPlaces.refreshAge + 1), "한 달이 지나면 다시 찾는다")
    }

    func testTravelToARealPlace() throws {
        let place = Place.find(.waterside)
        XCTAssertNil(Travel.roundTripMinutes(to: place, from: mapo, mode: .walk), "지도에서 찾기 전에는 갈 수 없다")
        let empty = NearbyPlaces(origin: mapo, foundAt: monday, places: [:])
        XCTAssertNil(Travel.roundTripMinutes(to: place, from: mapo, mode: .walk, nearby: empty), "근처에 없으면 갈 수 없다")
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: [.waterside: [venue("망원한강공원", 2)]])
        let minutes = try XCTUnwrap(Travel.roundTripMinutes(to: place, from: mapo, mode: .walk, nearby: found))
        XCTAssertEqual(Double(minutes), 2 * 2 * 1.3 / 4.5 * 60, accuracy: 2)
        XCTAssertEqual(Travel.venue(for: place, from: mapo, nearby: found)?.name, "망원한강공원")
        XCTAssertNil(Travel.roundTripMinutes(to: place, from: nil, mode: .walk, nearby: found), "위치 없이")
    }

    /// 근처에 실제로 있을 때만 그 실험이 나오고, 카드에 실제 장소가 붙는다.
    func testRecommendsOnlyWhatExistsNearby() {
        let river = Catalog.all.first { $0.id == "nature-stream" }!
        let home = Catalog.all.first { $0.id == "breath-4-6" }!
        let location = LocationSetting(kind: .neighborhood, region: Region(name: "마포", coordinate: mapo), mode: .walk)
        let checkIn = CheckIn(budget: .any, energy: .high, time: .fullDay, company: .solo)
        let without = Recommender(catalog: [river, home], allowSponsored: false, checkIn: checkIn, location: location)
        XCTAssertFalse(without.fits(river))
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: [.waterside: [venue("망원한강공원", 1.5)]])
        let with = Recommender(catalog: [river, home], allowSponsored: false, checkIn: checkIn, location: location, nearby: found)
        XCTAssertTrue(with.fits(river))
        var rng = SeededRandom(seed: 2)
        let picks = with.weeklyPicks(journal: Journal(), now: monday, count: 2, using: &rng)
        let riverPick = picks.first { $0.id == river.id }
        XCTAssertEqual(riverPick?.venue?.name, "망원한강공원")
        XCTAssertGreaterThan(riverPick?.travelMinutes ?? 0, 0)
        XCTAssertNil(picks.first { $0.id == home.id }?.venue)

        let short = Recommender(catalog: [river], allowSponsored: false, checkIn: CheckIn(budget: .any, energy: .high, time: .short, company: .solo), location: location, nearby: found)
        XCTAssertFalse(short.fits(river), "걸어서 왕복 50분이 넘으면 짧은 주에는 안 나온다")
    }

    func testEnoughCardsOnceTheNeighborhoodIsKnown() {
        let everywhere = Dictionary(uniqueKeysWithValues: PlaceNeed.allCases.map { ($0, [venue($0.title, 1)]) })
        let found = NearbyPlaces(origin: mapo, foundAt: monday, places: everywhere)
        let location = LocationSetting(kind: .neighborhood, region: Region(name: "마포", coordinate: mapo), mode: .transit)
        let recommender = Recommender(catalog: Catalog.all, allowSponsored: false, location: location, nearby: found)
        let none = Recommender(catalog: Catalog.all, allowSponsored: false, location: location)
        XCTAssertGreaterThan(Catalog.all.filter(recommender.fits).count, Catalog.all.filter(none.fits).count + 10)
    }
}

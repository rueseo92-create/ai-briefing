import Foundation

/// 실험에 필요한 실제 장소의 종류. 지도에서 동네 근처에 정말 있는지 찾아보고, 있을 때만 그 실험을 권한다.
public enum PlaceNeed: String, Codable, CaseIterable, Identifiable, Sendable {
    case park
    case waterside
    case trail
    case barefootPath
    case arboretum
    case library
    case bookstore
    case gallery
    case market
    case grocery
    case bakery
    case flowerShop
    case scentShop
    case sauna
    case quietYard
    case fitness
    case craftStudio
    case liveVenue
    case boardGameCafe
    case campfire
    case postOffice

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .park: "공원"
        case .waterside: "한강·천변"
        case .trail: "숲길·둘레길"
        case .barefootPath: "맨발길"
        case .arboretum: "수목원·식물원"
        case .library: "도서관"
        case .bookstore: "서점"
        case .gallery: "갤러리·미술관"
        case .market: "전통시장"
        case .grocery: "과일가게·마트"
        case .bakery: "빵집"
        case .flowerShop: "꽃집"
        case .scentShop: "향·캔들 가게"
        case .sauna: "목욕탕·사우나"
        case .quietYard: "절·성당"
        case .fitness: "운동 체험(클라이밍·요가)"
        case .craftStudio: "공방"
        case .liveVenue: "소극장·라이브 공연"
        case .boardGameCafe: "보드게임 카페"
        case .campfire: "캠핑장·불멍"
        case .postOffice: "우체국"
        }
    }

    /// 지도 검색어. 앞의 것부터 찾는다.
    public var queries: [String] {
        switch self {
        case .park: ["공원", "근린공원"]
        case .waterside: ["한강공원", "천변 산책로"]
        case .trail: ["둘레길", "숲길"]
        case .barefootPath: ["맨발길", "황톳길"]
        case .arboretum: ["수목원", "식물원"]
        case .library: ["도서관"]
        case .bookstore: ["서점", "독립서점"]
        case .gallery: ["갤러리", "미술관"]
        case .market: ["전통시장"]
        case .grocery: ["과일가게", "마트"]
        case .bakery: ["빵집", "베이커리"]
        case .flowerShop: ["꽃집"]
        case .scentShop: ["향수", "캔들"]
        case .sauna: ["목욕탕", "사우나"]
        case .quietYard: ["사찰", "성당"]
        case .fitness: ["클라이밍", "요가"]
        case .craftStudio: ["공방", "원데이 클래스"]
        case .liveVenue: ["소극장", "라이브 공연"]
        case .boardGameCafe: ["보드게임 카페"]
        case .campfire: ["캠핑장", "불멍"]
        case .postOffice: ["우체국"]
        }
    }

    /// 지도에서 찾을 범위(km). 이보다 먼 곳은 동네 실험으로 치지 않는다.
    public var radiusKm: Double {
        switch self {
        case .arboretum, .campfire, .trail: 25
        default: 8
        }
    }
}

/// 지도에서 찾아 둔 동네 근처의 실제 장소. 이 기기에만 저장한다.
public struct NearbyPlaces: Codable, Equatable, Sendable {
    public static let maxPerNeed = 5
    /// 이만큼 움직였거나 이만큼 지났으면 다시 찾는다.
    public static let refreshDistanceKm = 1.5
    public static let refreshAge: TimeInterval = 30 * 86_400

    public var origin: Coordinate
    public var foundAt: Date
    /// PlaceNeed.rawValue → 가까운 순서의 장소들.
    private var places: [String: [Venue]]

    public init(origin: Coordinate, foundAt: Date, places: [PlaceNeed: [Venue]]) {
        self.origin = origin
        self.foundAt = foundAt
        var byKey: [String: [Venue]] = [:]
        for (need, venues) in places {
            byKey[need.rawValue] = Self.cleaned(venues, need: need, around: origin)
        }
        self.places = byKey
    }

    public func venues(for need: PlaceNeed) -> [Venue] {
        places[need.rawValue] ?? []
    }

    public func nearest(_ need: PlaceNeed, from point: Coordinate) -> Venue? {
        venues(for: need).min { $0.coordinate.distanceKm(to: point) < $1.coordinate.distanceKm(to: point) }
    }

    public var missing: [PlaceNeed] {
        PlaceNeed.allCases.filter { venues(for: $0).isEmpty }
    }

    public func isFresh(for point: Coordinate, now: Date) -> Bool {
        origin.distanceKm(to: point) < Self.refreshDistanceKm && now.timeIntervalSince(foundAt) < Self.refreshAge
    }

    /// 범위 밖, 같은 곳(이름이 같고 200m 안) 을 빼고 가까운 순서로 몇 곳만.
    static func cleaned(_ venues: [Venue], need: PlaceNeed, around origin: Coordinate) -> [Venue] {
        var kept: [Venue] = []
        for venue in venues.sorted(by: { $0.coordinate.distanceKm(to: origin) < $1.coordinate.distanceKm(to: origin) }) {
            guard venue.coordinate.distanceKm(to: origin) <= need.radiusKm else { continue }
            let duplicate = kept.contains { $0.name == venue.name && $0.coordinate.distanceKm(to: venue.coordinate) < 0.2 }
            if !duplicate { kept.append(venue) }
            if kept.count == maxPerNeed { break }
        }
        return kept
    }
}

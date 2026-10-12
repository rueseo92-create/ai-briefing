import Foundation

/// 위도·경도. 기기 안에서 거리를 재는 데만 쓰고 서버로 보내지 않는다.
public struct Coordinate: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 두 점 사이 직선 거리(km). 하버사인 공식.
    public func distanceKm(to other: Coordinate) -> Double {
        let r = 6_371.0
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(latitude * .pi / 180) * cos(other.latitude * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * atan2(sqrt(a), sqrt(1 - a))
    }
}

/// 실험을 하는 곳.
public enum Place: Codable, Hashable, Sendable {
    /// 집에서. 오가는 시간 0분.
    case home
    /// 동네 어디서나(골목, 집 앞, 아무 카페). 오가는 시간은 정해 둔 값.
    case nearby(roundTripMinutes: Int)
    /// 공원, 한강, 도서관처럼 실제로 있어야 하는 곳. 지도에서 찾은 가장 가까운 곳까지 오가는 시간을 잰다.
    case find(PlaceNeed)
    /// 특정 장소. 내 위치에서의 거리로 오가는 시간을 잰다.
    case venue(Venue)

    public var isHome: Bool {
        if case .home = self { return true }
        return false
    }
}

public struct Venue: Codable, Hashable, Sendable {
    public var name: String
    public var coordinate: Coordinate
    public var address: String?

    public init(name: String, coordinate: Coordinate, address: String? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
    }
}

/// 작은 웰니스 실험 하나. 하루 안에 끝난다.
public struct Experiment: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var detail: String
    public var domain: Domain
    public var tags: [Tag]
    /// 실험 자체에 드는 시간(분). 오가는 시간은 따로 잰다.
    public var minutes: Int
    public var place: Place
    /// 예상 비용(원).
    public var cost: Int
    /// 혼자서는 할 수 없는 실험.
    public var needsCompany: Bool
    /// 광고주가 비용을 내고 소개하는 실험. 항상 "광고"로 표시한다.
    public var sponsor: Sponsorship?
    /// 미리 배송받을 수 있는 키트가 있는 실험.
    public var kit: Kit?
    /// 이 계절에만 나오는 카드. nil이면 사계절.
    public var seasons: [Season]?

    public init(
        id: String,
        title: String,
        detail: String,
        domain: Domain,
        tags: [Tag],
        minutes: Int,
        place: Place,
        cost: Int = 0,
        needsCompany: Bool = false,
        sponsor: Sponsorship? = nil,
        kit: Kit? = nil,
        seasons: [Season]? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.domain = domain
        self.tags = tags
        self.minutes = minutes
        self.place = place
        self.cost = max(0, cost)
        self.needsCompany = needsCompany
        self.sponsor = sponsor
        self.kit = kit
        self.seasons = seasons
    }

    public var isSponsored: Bool { sponsor != nil }

    public func isInSeason(at date: Date, calendar: Calendar = .current) -> Bool {
        seasons.map { $0.contains(Season.of(date, calendar: calendar)) } ?? true
    }

    /// 날씨를 타는 실험.
    public var isOutdoor: Bool {
        if tags.contains(.outdoors) { return true }
        if case .find(let need) = place { return need.isOutdoor }
        return false
    }

    /// 실제로 내게 될 돈. 광고 실험은 혜택을 받은 뒤 가격, 키트는 키트 가격.
    public var effectiveCost: Int {
        sponsor?.priceAfterBenefit ?? kit?.price ?? cost
    }
}

/// 광고 실험의 혜택. 광고주는 사용자의 기록, 예산, 위치를 받지 않는다.
public struct Sponsorship: Codable, Hashable, Sendable {
    public var brand: String
    /// 예: "첫 수업 40% 할인"
    public var benefit: String
    /// 혜택을 받은 뒤 내는 돈(원). 예산과 비교한다.
    public var priceAfterBenefit: Int
    public var code: String?
    public var url: URL?
    public var endsAt: Date?

    public init(brand: String, benefit: String, priceAfterBenefit: Int, code: String? = nil, url: URL? = nil, endsAt: Date? = nil) {
        self.brand = brand
        self.benefit = benefit
        self.priceAfterBenefit = max(0, priceAfterBenefit)
        self.code = code
        self.url = url
        self.endsAt = endsAt
    }

    public func isActive(at now: Date) -> Bool {
        endsAt.map { now < $0 } ?? true
    }
}

/// 주말 실험에 필요한 것을 미리 보내 주는 키트.
public struct Kit: Codable, Hashable, Sendable {
    public var name: String
    public var contents: [String]
    public var price: Int
    /// 주문하고 받기까지 걸리는 날.
    public var leadDays: Int
    public var url: URL?

    public init(name: String, contents: [String], price: Int, leadDays: Int, url: URL? = nil) {
        self.name = name
        self.contents = contents
        self.price = max(0, price)
        self.leadDays = max(1, leadDays)
        self.url = url
    }
}

import Foundation

/// 작은 취향 실험 하나. 하루 안에 끝나고, 대부분 돈이 거의 들지 않는다.
public struct Experiment: Codable, Hashable, Identifiable, Sendable {
    public enum Place: String, Codable, Sendable {
        case home
        case outside
    }

    public let id: String
    public var title: String
    public var detail: String
    public var domain: Domain
    public var tags: [Tag]
    public var minutes: Int
    public var place: Place
    /// 광고주가 비용을 내고 소개하는 실험. 화면에 항상 "광고"로 표시한다.
    public var sponsor: Sponsorship?
    /// 미리 배송받을 수 있는 키트가 있는 실험.
    public var kit: Kit?

    public init(
        id: String,
        title: String,
        detail: String,
        domain: Domain,
        tags: [Tag],
        minutes: Int,
        place: Place,
        sponsor: Sponsorship? = nil,
        kit: Kit? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.domain = domain
        self.tags = tags
        self.minutes = minutes
        self.place = place
        self.sponsor = sponsor
        self.kit = kit
    }

    public var isSponsored: Bool { sponsor != nil }
}

/// 광고 실험의 혜택. 광고주는 사용자의 취향 기록을 받지 않는다.
/// 고르는 일은 이 기기 안에서만 하고, 광고주에게는 혜택 코드가 쓰였는지만 전해진다.
public struct Sponsorship: Codable, Hashable, Sendable {
    public var brand: String
    /// 예: "첫 클래스 40% 할인"
    public var benefit: String
    public var code: String?
    public var url: URL?
    public var endsAt: Date?

    public init(brand: String, benefit: String, code: String? = nil, url: URL? = nil, endsAt: Date? = nil) {
        self.brand = brand
        self.benefit = benefit
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
    /// 원
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

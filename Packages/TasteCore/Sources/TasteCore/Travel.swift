import Foundation

public enum TravelMode: String, Codable, CaseIterable, Sendable {
    case walk
    case transit
    case car

    public var title: String {
        switch self {
        case .walk: "걸어서"
        case .transit: "대중교통"
        case .car: "차"
        }
    }

    /// 평균 속도(km/h). 대략의 값이다.
    var speedKmh: Double {
        switch self {
        case .walk: 4.5
        case .transit: 18
        case .car: 25
        }
    }

    /// 한 번 갈 때 더 드는 시간(분). 기다리기, 주차.
    var overheadMinutes: Double {
        switch self {
        case .walk: 0
        case .transit: 10
        case .car: 5
        }
    }
}

/// 위치를 어떻게 쓸지. 사용자가 고른다.
public struct LocationSetting: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        /// 구·동을 직접 고른다. 위치 권한이 필요 없다.
        case neighborhood
        /// iOS의 대략적 위치(수 km)를 실험을 받을 때만 쓴다.
        case approximate
        /// 집과 동네 실험만 받는다.
        case none
    }

    public var kind: Kind
    public var region: Region?
    /// 대략적 위치로 마지막에 받은 곳.
    public var approximate: Coordinate?
    public var mode: TravelMode

    public init(kind: Kind, region: Region? = nil, approximate: Coordinate? = nil, mode: TravelMode = .transit) {
        self.kind = kind
        self.region = region
        self.approximate = approximate
        self.mode = mode
    }

    public static let none = LocationSetting(kind: .none)

    /// 거리를 잴 출발점.
    public var origin: Coordinate? {
        switch kind {
        case .neighborhood: region?.coordinate
        case .approximate: approximate ?? region?.coordinate
        case .none: nil
        }
    }
}

public enum Travel {
    /// 길은 곧지 않으니 직선 거리에 곱한다.
    public static let detourFactor = 1.3

    /// 오가는 시간(왕복, 분). 갈 수 없으면(위치가 없는데 특정 장소) nil.
    public static func roundTripMinutes(to place: Place, from origin: Coordinate?, mode: TravelMode) -> Int? {
        switch place {
        case .home:
            return 0
        case .nearby(let minutes):
            return minutes
        case .venue(let venue):
            guard let origin else { return nil }
            let km = origin.distanceKm(to: venue.coordinate) * detourFactor
            let oneWay = km / mode.speedKmh * 60 + mode.overheadMinutes
            return Int((oneWay * 2).rounded(.up))
        }
    }
}

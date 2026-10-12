import Foundation

/// 동네. 위치 권한 없이 고르는 출발점이다. 좌표는 구청·시청 근처의 대략적인 값이다.
public struct Region: Codable, Hashable, Identifiable, Sendable {
    public var name: String
    public var coordinate: Coordinate
    public var id: String { name }

    public init(name: String, coordinate: Coordinate) {
        self.name = name
        self.coordinate = coordinate
    }
}

public enum Regions {
    private static func r(_ name: String, _ lat: Double, _ lon: Double) -> Region {
        Region(name: name, coordinate: Coordinate(latitude: lat, longitude: lon))
    }

    public static let all: [Region] = seoul + cities

    public static let seoul: [Region] = [
        r("서울 강남구", 37.5172, 127.0473), r("서울 강동구", 37.5301, 127.1238), r("서울 강북구", 37.6396, 127.0257),
        r("서울 강서구", 37.5509, 126.8495), r("서울 관악구", 37.4784, 126.9516), r("서울 광진구", 37.5385, 127.0823),
        r("서울 구로구", 37.4954, 126.8874), r("서울 금천구", 37.4569, 126.8955), r("서울 노원구", 37.6542, 127.0568),
        r("서울 도봉구", 37.6688, 127.0471), r("서울 동대문구", 37.5744, 127.0400), r("서울 동작구", 37.5124, 126.9393),
        r("서울 마포구", 37.5663, 126.9019), r("서울 서대문구", 37.5791, 126.9368), r("서울 서초구", 37.4837, 127.0324),
        r("서울 성동구", 37.5633, 127.0371), r("서울 성북구", 37.5894, 127.0167), r("서울 송파구", 37.5145, 127.1059),
        r("서울 양천구", 37.5169, 126.8664), r("서울 영등포구", 37.5264, 126.8962), r("서울 용산구", 37.5324, 126.9904),
        r("서울 은평구", 37.6027, 126.9291), r("서울 종로구", 37.5735, 126.9790), r("서울 중구", 37.5641, 126.9979),
        r("서울 중랑구", 37.6066, 127.0927),
    ]

    public static let cities: [Region] = [
        r("부산", 35.1796, 129.0756), r("대구", 35.8714, 128.6014), r("인천", 37.4563, 126.7052),
        r("광주", 35.1595, 126.8526), r("대전", 36.3504, 127.3845), r("울산", 35.5384, 129.3114),
        r("세종", 36.4800, 127.2890), r("수원", 37.2636, 127.0286), r("성남", 37.4200, 127.1267),
        r("고양", 37.6584, 126.8320), r("용인", 37.2411, 127.1776), r("제주", 33.4996, 126.5312),
    ]
}

import Foundation

public struct DayForecast: Codable, Equatable, Sendable {
    public var date: Date
    /// 0...1
    public var rainChance: Double
    /// 낮 최고 기온(°C)
    public var highC: Double

    public init(date: Date, rainChance: Double, highC: Double) {
        self.date = date
        self.rainChance = rainChance
        self.highC = highC
    }

    /// 바깥 실험 하기 좋은 날: 비 올 확률이 낮고 너무 덥거나 춥지 않다.
    public var isGoodOutside: Bool {
        rainChance < WeatherOutlook.rainyChance && highC < WeatherOutlook.hotC && highC > WeatherOutlook.coldC
    }
}

/// 동네의 이번 주 날씨. 바깥 실험을 고를 때만 쓴다.
public struct WeatherOutlook: Codable, Equatable, Sendable {
    public static let rainyChance = 0.6
    public static let hotC = 33.0
    public static let coldC = 0.0
    /// 바깥 실험하기 좋은 날이 이보다 적으면 "궂은 주"로 보고 실내 실험을 먼저 권한다.
    public static let minimumGoodDays = 2
    public static let freshFor: TimeInterval = 12 * 3_600

    public var origin: Coordinate
    public var fetchedAt: Date
    public var days: [DayForecast]

    public init(origin: Coordinate, fetchedAt: Date, days: [DayForecast]) {
        self.origin = origin
        self.fetchedAt = fetchedAt
        self.days = days
    }

    /// 오늘부터 남은 이번 주(최대 7일) 중 바깥 실험하기 좋은 날.
    public func goodDays(from now: Date, calendar: Calendar = .current) -> [DayForecast] {
        let today = calendar.startOfDay(for: now)
        return days.filter { $0.date >= today && $0.date < today.addingTimeInterval(7 * 86_400) && $0.isGoodOutside }
    }

    public func isRoughWeek(from now: Date, calendar: Calendar = .current) -> Bool {
        goodDays(from: now, calendar: calendar).count < Self.minimumGoodDays
    }

    /// 바깥 실험 카드에 붙는 한 줄. "좋은 날: 수·토"
    public func outdoorNote(from now: Date, calendar: Calendar = .current) -> String {
        let good = goodDays(from: now, calendar: calendar)
        if good.isEmpty { return "이번 주는 비나 더위·추위 소식이 많아요. 날이 좋을 때 해요" }
        return "바깥에 나가기 좋은 날: " + good.prefix(4).map { Week.weekdayName($0.date, calendar: calendar) }.joined(separator: "·")
    }

    public func isFresh(for point: Coordinate, now: Date) -> Bool {
        origin.distanceKm(to: point) < NearbyPlaces.refreshDistanceKm && now.timeIntervalSince(fetchedAt) < Self.freshFor
    }
}

import Foundation

/// 하루에 줄 수 있는 물방울. 적어야 한 방울이 의미를 가진다.
public struct CheerBudget: Codable, Equatable, Sendable {
    public static let dailyLimit = 3

    public private(set) var day: String
    public private(set) var used: Int

    public init(now: Date, calendar: Calendar = .current) {
        day = DayKey.make(now, calendar: calendar)
        used = 0
    }

    public func remaining(at now: Date, calendar: Calendar = .current) -> Int {
        guard DayKey.make(now, calendar: calendar) == day else { return Self.dailyLimit }
        return max(0, Self.dailyLimit - used)
    }

    /// 한 방울을 쓴다. 오늘 다 썼으면 false.
    public mutating func spend(at now: Date, calendar: Calendar = .current) -> Bool {
        let today = DayKey.make(now, calendar: calendar)
        if today != day {
            day = today
            used = 0
        }
        guard used < Self.dailyLimit else { return false }
        used += 1
        return true
    }
}

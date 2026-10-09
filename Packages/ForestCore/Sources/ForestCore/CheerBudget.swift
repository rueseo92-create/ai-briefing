import Foundation

/// 하루에 줄 수 있는 물방울. 적어야 한 방울이 의미를 가진다.
/// 같은 나무에는 하루 한 방울만. 앱을 다시 열어도 기억한다.
public struct CheerBudget: Codable, Equatable, Sendable {
    public static let dailyLimit = 3

    public private(set) var day: String
    public private(set) var used: Int
    /// 오늘 물을 준 나무들.
    public private(set) var wateredIDs: Set<String>

    public init(now: Date, calendar: Calendar = .current) {
        day = DayKey.make(now, calendar: calendar)
        used = 0
        wateredIDs = []
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(String.self, forKey: .day)
        used = try container.decode(Int.self, forKey: .used)
        // 이 필드가 생기기 전에 저장된 데이터도 읽는다.
        wateredIDs = try container.decodeIfPresent(Set<String>.self, forKey: .wateredIDs) ?? []
    }

    public func remaining(at now: Date, calendar: Calendar = .current) -> Int {
        guard DayKey.make(now, calendar: calendar) == day else { return Self.dailyLimit }
        return max(0, Self.dailyLimit - used)
    }

    public func hasWatered(_ treeID: String, at now: Date, calendar: Calendar = .current) -> Bool {
        DayKey.make(now, calendar: calendar) == day && wateredIDs.contains(treeID)
    }

    /// 한 방울을 쓴다. 오늘 다 썼거나 이 나무에 이미 줬으면 false.
    public mutating func spend(on treeID: String, at now: Date, calendar: Calendar = .current) -> Bool {
        let today = DayKey.make(now, calendar: calendar)
        if today != day {
            day = today
            used = 0
            wateredIDs = []
        }
        guard used < Self.dailyLimit, !wateredIDs.contains(treeID) else { return false }
        used += 1
        wateredIDs.insert(treeID)
        return true
    }
}

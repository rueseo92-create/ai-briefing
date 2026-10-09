import Foundation

/// 숲에서 온 물방울 하나. sender는 같은 사람이 여러 번 준 것을 묶는 데만 쓰고, 화면에는 보이지 않는다.
public struct IncomingCheer: Equatable, Sendable {
    public var sender: String?
    public var sentAt: Date

    public init(sender: String?, sentAt: Date) {
        self.sender = sender
        self.sentAt = sentAt
    }
}

/// 오늘 받은 물방울. 한 사람이 같은 날 여러 번 줘도 한 방울로 친다.
/// (하루 3방울 제한은 보내는 기기에서만 확인하니, 받는 쪽에서도 막는다)
public struct CheerInbox: Codable, Equatable, Sendable {
    public private(set) var day: String
    public private(set) var count: Int
    /// 오늘 물을 준 사람들. 날이 바뀌면 비운다.
    public private(set) var senders: Set<String>

    public init(now: Date, calendar: Calendar = .current) {
        self.init(day: DayKey.make(now, calendar: calendar), count: 0)
    }

    /// 예전에 저장한 "오늘 받은 물"을 이어받는다.
    public init(day: String, count: Int) {
        self.day = day
        self.count = max(0, count)
        self.senders = []
    }

    public func count(at now: Date, calendar: Calendar = .current) -> Int {
        DayKey.make(now, calendar: calendar) == day ? count : 0
    }

    /// 새로 받은 물방울 수를 돌려준다.
    public mutating func receive(_ cheers: [IncomingCheer], now: Date, calendar: Calendar = .current) -> Int {
        let today = DayKey.make(now, calendar: calendar)
        if today != day {
            day = today
            count = 0
            senders = []
        }
        var added = 0
        for cheer in cheers {
            if let sender = cheer.sender {
                guard senders.insert(sender).inserted else { continue }
            }
            added += 1
        }
        count += added
        return added
    }
}

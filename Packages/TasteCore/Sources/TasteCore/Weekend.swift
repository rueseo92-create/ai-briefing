import Foundation

/// 주말 키트 배송 일정.
public enum Weekend {
    /// 주문 마감 시각(시). 이 시각까지 주문하면 leadDays 뒤 토요일에 도착한다.
    public static let orderCutoffHour = 12

    public enum KitStatus: Equatable, Sendable {
        /// 마감 전에 주문하면 이번 주말에 받는다.
        case thisWeekend(orderBy: Date, saturday: Date)
        /// 이번 주는 늦었고 다음 주말에 받는다.
        case nextWeekend(orderBy: Date, saturday: Date)

        public var saturday: Date {
            switch self {
            case .thisWeekend(_, let saturday), .nextWeekend(_, let saturday): saturday
            }
        }

        public var orderBy: Date {
            switch self {
            case .thisWeekend(let date, _), .nextWeekend(let date, _): date
            }
        }
    }

    /// 다가오는 토요일 0시. 토요일이면 그날, 일요일이면 다음 토요일.
    public static func upcomingSaturday(from now: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today) // 1 = 일요일, 7 = 토요일
        let days = (7 - weekday + 7) % 7
        return calendar.date(byAdding: .day, value: days, to: today) ?? today
    }

    public static func orderDeadline(for kit: Kit, saturday: Date, calendar: Calendar = .current) -> Date {
        let day = calendar.date(byAdding: .day, value: -kit.leadDays, to: saturday) ?? saturday
        return calendar.date(bySettingHour: orderCutoffHour, minute: 0, second: 0, of: day) ?? day
    }

    public static func status(of kit: Kit, now: Date, calendar: Calendar = .current) -> KitStatus {
        var saturday = upcomingSaturday(from: now, calendar: calendar)
        var deadline = orderDeadline(for: kit, saturday: saturday, calendar: calendar)
        if now < deadline {
            return .thisWeekend(orderBy: deadline, saturday: saturday)
        }
        // 다음 주말에도 못 맞추는 경우(배송이 1주보다 오래 걸릴 때)까지 넘긴다.
        repeat {
            saturday = calendar.date(byAdding: .day, value: 7, to: saturday) ?? saturday
            deadline = orderDeadline(for: kit, saturday: saturday, calendar: calendar)
        } while now >= deadline
        return .nextWeekend(orderBy: deadline, saturday: saturday)
    }
}

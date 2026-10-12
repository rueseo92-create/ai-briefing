import Foundation

/// 기기 안에서만 울리는 알림 하나.
public struct Reminder: Equatable, Sendable {
    public let id: String
    public let date: Date
    public let title: String
    public let body: String

    public init(id: String, date: Date, title: String, body: String) {
        self.id = id
        self.date = date
        self.title = title
        self.body = body
    }
}

/// 한 주의 알림: 월요일 체크인, 키트 주문 마감 날 아침, 토요일 주말 계획.
public enum WeeklyReminders {
    public static let checkInID = "checkin"
    public static let kitID = "kit-deadline"
    public static let weekendID = "weekend-plan"
    public static let allIDs = [checkInID, kitID, weekendID]

    public static let checkInHour = 9
    public static let weekendHour = 10
    /// 마감 몇 시간 전에 알릴지.
    public static let kitLeadHours = 3

    public static func plan(now: Date, weekendPlan: Experiment?, calendar: Calendar = .current) -> [Reminder] {
        var reminders: [Reminder] = []

        if let monday = nextWeekday(2, hour: checkInHour, after: now, calendar: calendar) {
            reminders.append(Reminder(
                id: checkInID, date: monday,
                title: "이번 주 어때요?",
                body: "예산과 시간을 알려 주면 이번 주 실험 세 장을 골라 드려요."
            ))
        }

        if let plan = weekendPlan {
            if let kit = plan.kit, case .thisWeekend(let orderBy, _) = Weekend.status(of: kit, now: now, calendar: calendar) {
                let at = orderBy.addingTimeInterval(-Double(kitLeadHours) * 3_600)
                if at > now {
                    reminders.append(Reminder(
                        id: kitID, date: at,
                        title: "키트 주문 마감이 오늘 낮 12시예요",
                        body: "\(kit.name) · 지금 주문하면 이번 토요일에 받아요."
                    ))
                }
            }
            let saturday = Weekend.upcomingSaturday(from: now, calendar: calendar)
            if let at = calendar.date(bySettingHour: weekendHour, minute: 0, second: 0, of: saturday), at > now {
                reminders.append(Reminder(
                    id: weekendID, date: at,
                    title: "이번 주말 계획",
                    body: "\(plan.title). 다녀오면 엽서로 남겨요."
                ))
            }
        }
        return reminders
    }

    /// now 뒤의 가장 가까운 그 요일 그 시각. weekday: 1 = 일요일.
    static func nextWeekday(_ weekday: Int, hour: Int, after now: Date, calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.weekday = weekday
        parts.hour = hour
        parts.minute = 0
        return calendar.nextDate(after: now, matching: parts, matchingPolicy: .nextTime)
    }
}

import Foundation

public enum Week {
    /// "2026-W42"
    public static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", parts.yearForWeekOfYear ?? 0, parts.weekOfYear ?? 0)
    }

    static let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    /// "수"
    public static func weekdayName(_ date: Date, calendar: Calendar = .current) -> String {
        weekdayNames[(calendar.component(.weekday, from: date) - 1 + 7) % 7]
    }
}

/// 계절. 계절 카드는 그 계절에만 나온다.
public enum Season: String, Codable, CaseIterable, Sendable {
    case spring
    case summer
    case autumn
    case winter

    public init(month: Int) {
        switch month {
        case 3...5: self = .spring
        case 6...8: self = .summer
        case 9...11: self = .autumn
        default: self = .winter
        }
    }

    public static func of(_ date: Date, calendar: Calendar = .current) -> Season {
        Season(month: calendar.component(.month, from: date))
    }

    public var title: String {
        switch self {
        case .spring: "봄"
        case .summer: "여름"
        case .autumn: "가을"
        case .winter: "겨울"
        }
    }
}

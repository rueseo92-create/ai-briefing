import Foundation

public struct Milestone: Identifiable, Equatable, Sendable {
    public let days: Int
    public var id: Int { days }

    public var title: String {
        switch days {
        case 1: "첫 하루"
        case 7: "일주일"
        case 30: "한 달"
        case 100: "백 일"
        case 365: "일 년"
        default: "\(days)일"
        }
    }
}

/// 배지는 "지금까지 참은 날" 기준이라 한 번 받으면 사라지지 않는다.
public enum Milestones {
    public static let all: [Milestone] = [1, 3, 7, 14, 30, 50, 100, 200, 365].map(Milestone.init(days:))

    public static func reached(cleanDays: Int) -> [Milestone] {
        all.filter { $0.days <= cleanDays }
    }

    public static func next(cleanDays: Int) -> Milestone? {
        all.first { $0.days > cleanDays }
    }
}

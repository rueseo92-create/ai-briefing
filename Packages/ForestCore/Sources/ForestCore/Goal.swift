import Foundation

/// 내가 정한 목표. "지금까지 참은 날" 기준이라 한 번 다시 했다고 목표가 날아가지 않는다.
/// 기기에만 저장되고 숲에는 보이지 않는다.
public enum Goal: Codable, Hashable, Sendable {
    case days(Int)
    case lifetime

    public static let maxDays = 3_650

    public static let presets: [Goal] = [.days(7), .days(30), .days(70), .days(100), .days(365), .lifetime]

    /// 직접 입력한 일수. 1일 ~ 10년으로 맞춘다.
    public static func custom(_ days: Int) -> Goal {
        .days(min(max(1, days), maxDays))
    }

    /// 지금 고를 수 있는 목표: 이미 넘긴 일수는 빼고, 평생은 항상 넣는다.
    public static func choices(cleanDays: Int) -> [Goal] {
        presets.filter { goal in
            guard let target = goal.targetDays else { return true }
            return target > cleanDays
        }
    }

    public var targetDays: Int? {
        switch self {
        case .days(let days): days
        case .lifetime: nil
        }
    }

    public var title: String {
        switch self {
        case .days(365): "1년"
        case .days(let days): "\(days)일"
        case .lifetime: "평생"
        }
    }

    /// 0...1. 평생은 끝이 없으니 nil.
    public func progress(cleanDays: Int) -> Double? {
        guard let target = targetDays, target > 0 else { return nil }
        return min(1, Double(max(0, cleanDays)) / Double(target))
    }

    public func remaining(cleanDays: Int) -> Int? {
        targetDays.map { max(0, $0 - cleanDays) }
    }

    public func isReached(cleanDays: Int) -> Bool {
        guard let target = targetDays else { return false }
        return cleanDays >= target
    }
}

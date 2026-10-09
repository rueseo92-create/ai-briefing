import Foundation

/// 끊으려는 것의 종류. 이 값은 기기 밖으로 절대 나가지 않는다.
public enum HabitKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case smoking
    case drinking
    case gambling
    case shortForm
    case lateNightSnack
    case gaming
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .smoking: "담배"
        case .drinking: "술"
        case .gambling: "도박"
        case .shortForm: "쇼츠·릴스"
        case .lateNightSnack: "야식"
        case .gaming: "게임"
        case .custom: "직접 입력"
        }
    }

    public var emoji: String {
        switch self {
        case .smoking: "🚬"
        case .drinking: "🍺"
        case .gambling: "🎰"
        case .shortForm: "📱"
        case .lateNightSnack: "🍗"
        case .gaming: "🎮"
        case .custom: "✏️"
        }
    }
}

/// 사고 싶은 것. 아낀 돈이 채워 나가는 목표.
public struct Wish: Codable, Equatable, Sendable {
    public var title: String
    public var price: Int

    public init(title: String, price: Int) {
        self.title = title
        self.price = price
    }

    public func progress(saved: Int) -> Double {
        guard price > 0 else { return 0 }
        return min(1, Double(max(0, saved)) / Double(price))
    }
}

/// 내가 끊고 있는 것. 전부 이 기기에만 저장된다.
public struct Habit: Codable, Equatable, Sendable {
    /// 다시 했을 때 "지금까지 참은 시간"에서 빠지는 양. 0으로 리셋하지 않는다.
    public static let slipPenalty: TimeInterval = 86_400
    /// 다시 한 뒤 나무가 시들어 있는 시간.
    public static let wiltDuration: TimeInterval = 86_400

    public var kind: HabitKind
    public var customTitle: String?
    /// 끊기 시작한 시각(= 마지막으로 한 시각).
    public var startedAt: Date
    /// 다시 한 시각들.
    public var slips: [Date]
    /// 하루에 보통 쓰던 돈(원).
    public var dailyCost: Int
    /// 끊으려는 이유. 참기 화면에서 다시 보여 준다.
    public var reason: String
    /// 참기 버튼을 누르고 버텨 낸 횟수.
    public var urgeWins: Int
    public var wish: Wish?
    public var goal: Goal?

    public init(
        kind: HabitKind,
        customTitle: String? = nil,
        startedAt: Date,
        dailyCost: Int = 0,
        reason: String = "",
        goal: Goal? = nil
    ) {
        self.kind = kind
        self.customTitle = customTitle
        self.startedAt = startedAt
        self.slips = []
        self.dailyCost = max(0, dailyCost)
        self.reason = reason
        self.urgeWins = 0
        self.wish = nil
        self.goal = goal
    }

    public var title: String {
        guard kind == .custom else { return kind.title }
        let trimmed = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "나의 습관" : trimmed
    }

    public var lastSlipAt: Date? { slips.max() }

    /// 지금 이어가고 있는 구간의 시작.
    public var streakStart: Date {
        guard let last = lastSlipAt else { return startedAt }
        return max(last, startedAt)
    }

    /// 마지막으로 다시 한 뒤 지난 시간.
    public func currentStreak(at now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince(streakStart))
    }

    /// 지금까지 참은 시간. 다시 해도 0이 되지 않고 하루씩만 빠진다.
    public func totalClean(at now: Date) -> TimeInterval {
        let elapsed = max(0, now.timeIntervalSince(startedAt))
        let penalty = Double(slips.count) * Self.slipPenalty
        return max(currentStreak(at: now), elapsed - penalty)
    }

    public func totalCleanDays(at now: Date) -> Int {
        Int(totalClean(at: now) / 86_400)
    }

    /// 다시 하지 않고 이어 가면 "지금까지 참은 날"이 days가 되는 시각. 이미 넘겼으면 nil.
    public func date(reachingCleanDays days: Int, after now: Date) -> Date? {
        let from = max(now, startedAt)
        let needed = Double(days) * 86_400 - totalClean(at: from)
        guard needed > 0 else { return nil }
        return from.addingTimeInterval(needed)
    }

    public func isWilting(at now: Date) -> Bool {
        guard let last = lastSlipAt else { return false }
        let since = now.timeIntervalSince(last)
        return since >= 0 && since < Self.wiltDuration
    }

    public func moneySaved(at now: Date) -> Int {
        Int((Double(dailyCost) * totalClean(at: now) / 86_400).rounded(.down))
    }

    public func stage(at now: Date) -> GrowthStage {
        GrowthStage(cleanDays: totalCleanDays(at: now))
    }

    public mutating func recordSlip(at date: Date) {
        slips.append(date)
    }

    public mutating func recordUrgeWin() {
        urgeWins += 1
    }
}

import Foundation

/// "다른 걸로"를 누른 이유에서 배운 것. 최근 4주만 본다.
public struct SwapLearning: Equatable, Sendable {
    public static let window: TimeInterval = 28 * 86_400
    /// 이만큼 같은 이유가 쌓이면 추천에 반영한다.
    public static let threshold = 2
    /// 이만큼 쌓이면 체크인 기본값을 바꾸자고 제안한다.
    public static let suggestAt = 3

    public var costSensitive: Bool
    public var timeSensitive: Bool
    /// "마음이 안 가서"로 자주 넘긴 구역.
    public var coolDomains: Set<Domain>
    public var noTimeCount: Int

    public init(journal: Journal, now: Date) {
        let recent = journal.swaps.filter { now.timeIntervalSince($0.at) < Self.window && $0.at <= now }
        costSensitive = recent.filter { $0.reason == .tooExpensive }.count >= Self.threshold
        noTimeCount = recent.filter { $0.reason == .noTime }.count
        timeSensitive = noTimeCount >= Self.threshold
        let cool = Dictionary(grouping: recent.filter { $0.reason == .notFeelingIt }.compactMap(\.domain)) { $0 }
        coolDomains = Set(cool.filter { $0.value.count >= Self.suggestAt }.keys)
    }

    /// 추천 점수에서 뺄 값.
    public func penalty(_ experiment: Experiment, travelMinutes: Int) -> Int {
        var penalty = 0
        if costSensitive { penalty += experiment.effectiveCost / 10_000 }
        if timeSensitive, experiment.minutes + travelMinutes > 60 { penalty += 2 }
        if coolDomains.contains(experiment.domain) { penalty += 3 }
        return penalty
    }

    /// 체크인 기본값을 바꾸자는 제안. 이미 그렇거나 쌓인 게 적으면 nil.
    public func suggestion(for checkIn: CheckIn) -> CheckIn? {
        guard noTimeCount >= Self.suggestAt, checkIn.time != .short else { return nil }
        var changed = checkIn
        changed.time = CheckIn.TimeBudget(rawValue: checkIn.time.rawValue - 1) ?? .short
        return changed
    }
}

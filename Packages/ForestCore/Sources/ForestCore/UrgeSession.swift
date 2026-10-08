import Foundation

/// 참기 버튼을 누른 뒤 충동이 지나갈 때까지 버티는 시간.
public struct UrgeSession: Equatable, Sendable {
    public static let defaultDuration: TimeInterval = 10 * 60
    /// 숲에서 "지금 참는 중"으로 보이는 최대 시간. 앱이 꺼져도 영원히 흔들리지 않게.
    public static let publicWindow: TimeInterval = 15 * 60

    public let startedAt: Date
    public let duration: TimeInterval

    public init(startedAt: Date, duration: TimeInterval = UrgeSession.defaultDuration) {
        self.startedAt = startedAt
        self.duration = duration
    }

    public func remaining(at now: Date) -> TimeInterval {
        max(0, duration - now.timeIntervalSince(startedAt))
    }

    public func progress(at now: Date) -> Double {
        guard duration > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(startedAt) / duration))
    }

    public func isFinished(at now: Date) -> Bool {
        remaining(at: now) <= 0
    }
}

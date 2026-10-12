import Foundation

/// 구역별 우표. 한 번이라도 해 보면 그 구역 우표가 생기고, 좋았던 실험이 세 번이면 금색이 된다.
public struct StampState: Equatable, Identifiable, Sendable {
    public static let goldLikes = 3

    public var domain: Domain
    public var postcards: Int
    public var liked: Int

    public var id: Domain { domain }
    public var earned: Bool { postcards > 0 }
    public var isGold: Bool { liked >= Self.goldLikes }
}

public enum Stamps {
    public static func board(_ journal: Journal) -> [StampState] {
        Domain.allCases.map { domain in
            let entries = journal.entries.filter { $0.domain == domain }
            return StampState(domain: domain, postcards: entries.count, liked: entries.filter { $0.feeling == .liked }.count)
        }
    }

    /// 이 기록으로 새로 생긴 우표. 첫 우표거나 금색이 된 순간.
    public static func newlyEarned(before: Journal, after: Journal) -> [StampState] {
        let old = Dictionary(uniqueKeysWithValues: board(before).map { ($0.domain, $0) })
        return board(after).filter { stamp in
            guard let previous = old[stamp.domain] else { return stamp.earned }
            return (stamp.earned && !previous.earned) || (stamp.isGold && !previous.isGold)
        }
    }
}

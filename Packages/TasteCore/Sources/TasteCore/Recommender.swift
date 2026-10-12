import Foundation

/// 한 번에 받는 실험 세 장의 자리. 알고리즘이 "이미 좋아한 것"만 권하지 않도록, 늘 한 장은 처음 가 보는 쪽에서 고른다.
public enum Slot: String, Codable, CaseIterable, Sendable {
    /// 좋았던 이유와 결이 같은 것
    case confirm
    /// 좋았던 이유는 같고 분야는 낯선 것
    case sideStep
    /// 아직 덜 가 본 지역
    case fresh

    public var title: String {
        switch self {
        case .confirm: "결이 같은"
        case .sideStep: "옆으로 한 칸"
        case .fresh: "처음 가 보는"
        }
    }
}

public struct Pick: Codable, Equatable, Identifiable, Sendable {
    public var experiment: Experiment
    public var slot: Slot
    /// 왜 이걸 권하는지. 카드에 그대로 보인다.
    public var reason: String
    public var id: String { experiment.id }
}

public struct Recommender: Sendable {
    /// 이 기간 안에 보였던 실험은 다른 게 남아 있는 한 다시 권하지 않는다.
    public static let recentWindow: TimeInterval = 21 * 86_400
    /// 넘긴 실험은 이 기간 동안 나오지 않는다.
    public static let skipCooldown: TimeInterval = 30 * 86_400

    public var catalog: [Experiment]
    /// 광고 실험을 받을지. 꺼도 앱은 똑같이 쓸 수 있다.
    public var allowSponsored: Bool

    public init(catalog: [Experiment], allowSponsored: Bool) {
        self.catalog = catalog
        self.allowSponsored = allowSponsored
    }

    /// 이번 주 실험. 세 장 모두 다른 분야에서 나오고, 광고는 많아야 한 장이며 "결이 같은" 자리에는 오지 않는다.
    public func weeklyPicks<R: RandomNumberGenerator>(journal: Journal, now: Date, count: Int = 3, using rng: inout R) -> [Pick] {
        let profile = TasteProfile(journal: journal)
        let slots: [Slot] = profile.hasLikes
            ? Array([Slot.confirm, .sideStep, .fresh, .fresh, .sideStep].prefix(count))
            : Array(repeating: .fresh, count: count)
        var picks: [Pick] = []
        for slot in slots {
            let next = pick(
                slot: slot,
                journal: journal,
                now: now,
                excluding: Set(picks.map(\.id)),
                avoidDomains: Set(picks.map(\.experiment.domain)),
                sponsorAllowed: !picks.contains { $0.experiment.isSponsored },
                using: &rng
            )
            if let next { picks.append(next) }
        }
        return picks
    }

    /// 한 자리만 다시 고른다. "다른 걸로 바꾸기"에 쓴다.
    public func pick<R: RandomNumberGenerator>(
        slot: Slot,
        journal: Journal,
        now: Date,
        excluding: Set<String>,
        avoidDomains: Set<Domain>,
        sponsorAllowed: Bool,
        using rng: inout R
    ) -> Pick? {
        let profile = TasteProfile(journal: journal)
        let base = catalog.filter { experiment in
            !excluding.contains(experiment.id)
                && !journal.hasTried(experiment.id)
                && !isCoolingDown(experiment.id, journal: journal, now: now)
                && (experiment.sponsor?.isActive(at: now) ?? true)
        }
        // 최근에 보인 것은 빼되, 그러면 남는 게 없을 때만 다시 넣는다.
        let fresh = base.filter { !wasShownRecently($0.id, journal: journal, now: now) }
        for pool in [fresh, base] {
            let spread = pool.filter { !avoidDomains.contains($0.domain) }
            for candidates in [spread, pool] where !candidates.isEmpty {
                if let found = choose(slot: slot, from: candidates, profile: profile, sponsorAllowed: sponsorAllowed, using: &rng) {
                    return found
                }
            }
        }
        return nil
    }

    /// 주말 키트가 있는 실험. 나와 맞을 것 같은 순서로.
    public func weekendIdeas(journal: Journal, now: Date, limit: Int = 5) -> [Experiment] {
        let profile = TasteProfile(journal: journal)
        return catalog
            .filter { $0.kit != nil && !journal.hasTried($0.id) && !profile.hasDislikedTag($0) && ($0.sponsor?.isActive(at: now) ?? true) }
            .sorted { profile.score($0) > profile.score($1) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - 내부

    private func choose<R: RandomNumberGenerator>(
        slot: Slot,
        from candidates: [Experiment],
        profile: TasteProfile,
        sponsorAllowed: Bool,
        using rng: inout R
    ) -> Pick? {
        let organic = candidates.filter { !$0.isSponsored }
        // 광고는 이 자리의 기준을 통과하고, 싫어한 이유가 없고, 점수가 0 이상일 때만 들어올 수 있다.
        let sponsored = (allowSponsored && sponsorAllowed && slot != .confirm)
            ? candidates.filter { $0.isSponsored && !profile.hasDislikedTag($0) && profile.score($0) >= 0 }
            : []

        let organicPick = rule(for: slot, candidates: organic, profile: profile, using: &rng)
        if !sponsored.isEmpty, organicPick == nil || Bool.random(using: &rng),
           let ad = rule(for: slot, candidates: sponsored, profile: profile, using: &rng) {
            return ad
        }
        return organicPick
    }

    private func rule<R: RandomNumberGenerator>(for slot: Slot, candidates: [Experiment], profile: TasteProfile, using rng: inout R) -> Pick? {
        guard !candidates.isEmpty else { return nil }
        switch slot {
        case .confirm:
            let top = profile.topTags(3)
            let liked = Set(profile.likedDomains)
            let matching = candidates.filter { experiment in experiment.tags.contains(where: top.contains) && !profile.hasDislikedTag(experiment) }
            guard let chosen = best(matching, by: { profile.score($0) + (liked.contains($0.domain) ? 2 : 0) }, using: &rng) else { return nil }
            let tag = chosen.tags.first(where: top.contains) ?? top[0]
            return Pick(experiment: chosen, slot: .confirm, reason: "‘\(tag.title)’ 좋았던 실험과 결이 같아요")

        case .sideStep:
            let top = profile.topTags(2)
            guard !top.isEmpty else { return nil }
            let anchor = top.randomElement(using: &rng) ?? top[0]
            let familiar = Set(profile.likedDomains.prefix(2))
            let matching = candidates.filter { experiment in
                experiment.tags.contains(anchor)
                    && !familiar.contains(experiment.domain)
                    && profile.stat(experiment.domain).state != .notForMe
                    && !profile.hasDislikedTag(experiment)
            }
            guard let chosen = best(matching, by: profile.score, using: &rng) else { return nil }
            let place = profile.stat(chosen.domain).tried == 0 ? "‘\(chosen.domain.title)’ 쪽은 처음이에요" : "이번엔 ‘\(chosen.domain.title)’ 쪽에서 해 봐요"
            return Pick(experiment: chosen, slot: .sideStep, reason: "‘\(anchor.title)’ 좋았던 건 같고, \(place)")

        case .fresh:
            let open = candidates.filter { profile.stat($0.domain).state != .notForMe && !profile.hasDislikedTag($0) }
            let pool = open.isEmpty ? candidates : open
            guard let fewest = pool.map({ profile.stat($0.domain).tried }).min() else { return nil }
            let frontier = pool.filter { profile.stat($0.domain).tried == fewest }
            guard let chosen = frontier.randomElement(using: &rng) else { return nil }
            let reason: String
            if profile.entryCount == 0 {
                reason = "첫 실험은 여러 지역에서 하나씩 골랐어요"
            } else if fewest == 0 {
                reason = "아직 안 가 본 ‘\(chosen.domain.title)’ 지역이에요"
            } else {
                reason = "덜 가 본 ‘\(chosen.domain.title)’ 지역이에요"
            }
            return Pick(experiment: chosen, slot: .fresh, reason: reason)
        }
    }

    /// 점수 상위 셋 중 하나. 늘 1등만 고르면 매번 같은 게 나온다.
    private func best<R: RandomNumberGenerator>(_ candidates: [Experiment], by score: (Experiment) -> Int, using rng: inout R) -> Experiment? {
        let ranked = candidates.shuffled(using: &rng).sorted { score($0) > score($1) }
        return ranked.prefix(3).randomElement(using: &rng)
    }

    private func wasShownRecently(_ id: String, journal: Journal, now: Date) -> Bool {
        guard let at = journal.shown[id] else { return false }
        return now.timeIntervalSince(at) < Self.recentWindow
    }

    private func isCoolingDown(_ id: String, journal: Journal, now: Date) -> Bool {
        guard let at = journal.skipped[id] else { return false }
        return now.timeIntervalSince(at) < Self.skipCooldown
    }
}

/// 시드로 고정되는 난수. 테스트에서 같은 결과를 얻기 위해 쓴다.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

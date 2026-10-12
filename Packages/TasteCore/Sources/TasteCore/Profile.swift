import Foundation

public struct DomainStat: Equatable, Sendable {
    public var tried = 0
    public var liked = 0
    public var disliked = 0

    public init(tried: Int = 0, liked: Int = 0, disliked: Int = 0) {
        self.tried = tried
        self.liked = liked
        self.disliked = disliked
    }

    /// 지도에서 이 지역이 얼마나 밝혀졌는지. 4번 해 보면 다 밝혀진다.
    public var light: Double { min(1, Double(tried) / 4) }

    public var state: DomainState {
        if tried == 0 { return .unexplored }
        if liked >= 2 && liked > disliked { return .favorite }
        if disliked >= 2 && disliked > liked { return .notForMe }
        return .exploring
    }
}

public enum DomainState: Sendable {
    case unexplored
    case exploring
    case favorite
    case notForMe

    public var title: String {
        switch self {
        case .unexplored: "아직 안 가 봄"
        case .exploring: "알아 가는 중"
        case .favorite: "좋아하는 곳"
        case .notForMe: "나랑은 잘 안 맞음"
        }
    }
}

/// 기록에서 읽어 낸 취향. 좋았던 이유는 크게, 실험에 붙은 태그는 작게 센다.
public struct TasteProfile: Equatable, Sendable {
    public private(set) var tagScores: [Tag: Int] = [:]
    public private(set) var domainStats: [Domain: DomainStat] = [:]
    public let entryCount: Int

    public init(journal: Journal) {
        entryCount = journal.entries.count
        for entry in journal.entries {
            var stat = domainStats[entry.domain] ?? DomainStat()
            stat.tried += 1
            let sign: Int
            switch entry.feeling {
            case .liked:
                sign = 1
                stat.liked += 1
            case .meh:
                sign = 0
            case .disliked:
                sign = -1
                stat.disliked += 1
            }
            domainStats[entry.domain] = stat
            for tag in entry.tags { tagScores[tag, default: 0] += sign }
            for tag in entry.why { tagScores[tag, default: 0] += sign * 2 }
        }
    }

    public func stat(_ domain: Domain) -> DomainStat {
        domainStats[domain] ?? DomainStat()
    }

    public var hasLikes: Bool { domainStats.values.contains { $0.liked > 0 } }

    /// 점수가 높은 이유부터. 같으면 Tag 순서대로.
    public func topTags(_ limit: Int = 3) -> [Tag] {
        Tag.allCases
            .filter { (tagScores[$0] ?? 0) > 0 }
            .sorted { (tagScores[$0] ?? 0) > (tagScores[$1] ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    /// 가장 안 맞았던 이유부터.
    public var dislikedTags: [Tag] {
        Tag.allCases
            .filter { (tagScores[$0] ?? 0) < 0 }
            .sorted { (tagScores[$0] ?? 0) < (tagScores[$1] ?? 0) }
    }

    /// 좋았던 실험이 있는 지역, 많은 순.
    public var likedDomains: [Domain] {
        Domain.allCases
            .filter { stat($0).liked > stat($0).disliked }
            .sorted { stat($0).liked > stat($1).liked }
    }

    public var unexplored: [Domain] {
        Domain.allCases.filter { stat($0).tried == 0 }
    }

    /// 이 실험이 나랑 얼마나 맞을 것 같은지.
    public func score(_ experiment: Experiment) -> Int {
        let tags = experiment.tags.reduce(0) { $0 + (tagScores[$1] ?? 0) }
        let stat = stat(experiment.domain)
        return tags + stat.liked - stat.disliked * 2
    }

    public func hasDislikedTag(_ experiment: Experiment) -> Bool {
        experiment.tags.contains { (tagScores[$0] ?? 0) < 0 }
    }
}

/// 몇 번 해 본 뒤 보여 주는 취향 정리.
public struct TasteSummary: Equatable, Sendable {
    public var headline: String
    public var lines: [String]
    public var topTags: [Tag]
    public var nextFrontier: Domain?
}

public enum Insight {
    public static let minimumEntries = 5

    public static func summarize(_ journal: Journal) -> TasteSummary? {
        guard journal.entries.count >= minimumEntries else { return nil }
        let profile = TasteProfile(journal: journal)
        let top = profile.topTags(3)
        guard let first = top.first else {
            return TasteSummary(
                headline: "아직 찾는 중인 사람",
                lines: ["좋았던 실험이 아직 없어요. 별로인 걸 아는 것도 취향이에요. 조금 더 다른 쪽으로 가 봐요."],
                topTags: [],
                nextFrontier: profile.unexplored.first
            )
        }

        var lines: [String] = []
        lines.append(top.map { "‘\($0.title)’" }.joined(separator: ", ") + " 좋았던 적이 많아요.")

        // 분야가 달라도 같은 이유로 좋았다면, 그게 진짜 취향이다.
        let likedDomainsForTop = Set(journal.entries.filter { $0.feeling == .liked && ($0.why.contains(first) || $0.tags.contains(first)) }.map(\.domain))
        if likedDomainsForTop.count >= 2 {
            let names = Domain.allCases.filter(likedDomainsForTop.contains).map(\.title).joined(separator: ", ")
            lines.append("\(names)처럼 분야는 달라도 ‘\(first.title)’가 공통점이에요.")
        }
        if let favorite = profile.likedDomains.first, profile.stat(favorite).liked >= 2 {
            lines.append("‘\(favorite.title)’ 쪽에서 좋았던 실험이 가장 많아요.")
        }
        if let disliked = profile.dislikedTags.first {
            lines.append("‘\(disliked.title)’는 아직 잘 안 맞았어요. 별로인 걸 아는 것도 취향이에요.")
        }
        let frontier = profile.unexplored.first
        if let frontier {
            lines.append("아직 ‘\(frontier.title)’ 지역은 안 가 봤어요.")
        }
        return TasteSummary(headline: "\(first.persona) 사람", lines: lines, topTags: top, nextFrontier: frontier)
    }
}

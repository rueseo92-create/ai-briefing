import Foundation

public enum Feeling: String, Codable, CaseIterable, Sendable {
    case liked
    case meh
    case disliked

    public var title: String {
        switch self {
        case .liked: "좋았어요"
        case .meh: "그저 그랬어요"
        case .disliked: "별로였어요"
        }
    }

    public var emoji: String {
        switch self {
        case .liked: "😊"
        case .meh: "😐"
        case .disliked: "🙅"
        }
    }
}

/// 실험 하나를 해 본 기록. 실험 카드가 나중에 바뀌거나 사라져도 지도가 그대로이게, 그때의 분야와 태그를 함께 적어 둔다.
public struct Entry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var experimentID: String
    public var title: String
    public var domain: Domain
    public var tags: [Tag]
    public var feeling: Feeling
    /// 왜 그랬는지. 실험 태그 중에서 고른다.
    public var why: [Tag]
    public var note: String
    public var at: Date

    public init(experiment: Experiment, feeling: Feeling, why: [Tag], note: String = "", at: Date) {
        id = UUID()
        experimentID = experiment.id
        title = experiment.title
        domain = experiment.domain
        tags = experiment.tags
        self.feeling = feeling
        self.why = why.filter(experiment.tags.contains)
        self.note = note
        self.at = at
    }
}

/// 내 실험 기록 전부. 이 기기에만 저장된다.
public struct Journal: Codable, Equatable, Sendable {
    public private(set) var entries: [Entry] = []
    /// 마지막으로 추천에 보인 때. 같은 실험이 자꾸 나오지 않게.
    public private(set) var shown: [String: Date] = [:]
    /// 넘긴 실험. 한동안 다시 나오지 않는다.
    public private(set) var skipped: [String: Date] = [:]

    public init() {}

    public func hasTried(_ experimentID: String) -> Bool {
        entries.contains { $0.experimentID == experimentID }
    }

    public mutating func record(_ entry: Entry) {
        entries.append(entry)
    }

    public mutating func markShown(_ ids: [String], at now: Date) {
        for id in ids { shown[id] = now }
    }

    public mutating func skip(_ experimentID: String, at now: Date) {
        skipped[experimentID] = now
    }
}

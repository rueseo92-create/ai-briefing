import Foundation

/// 나무의 모습. 숲에서는 정확한 일수 대신 이것만 보인다.
public enum GrowthStage: Int, Codable, CaseIterable, Comparable, Sendable {
    case seed
    case sprout
    case sapling
    case youngTree
    case tree
    case blossom
    case fruit
    case grand

    /// 이 모습이 되기 위해 필요한, 지금까지 참은 날.
    public var requiredDays: Int {
        switch self {
        case .seed: 0
        case .sprout: 1
        case .sapling: 3
        case .youngTree: 7
        case .tree: 21
        case .blossom: 60
        case .fruit: 120
        case .grand: 365
        }
    }

    public var title: String {
        switch self {
        case .seed: "씨앗"
        case .sprout: "새싹"
        case .sapling: "묘목"
        case .youngTree: "어린 나무"
        case .tree: "나무"
        case .blossom: "꽃 핀 나무"
        case .fruit: "열매 맺은 나무"
        case .grand: "큰 나무"
        }
    }

    public init(cleanDays: Int) {
        self = Self.allCases.last { $0.requiredDays <= cleanDays } ?? .seed
    }

    public var next: GrowthStage? {
        GrowthStage(rawValue: rawValue + 1)
    }

    public static func < (lhs: GrowthStage, rhs: GrowthStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

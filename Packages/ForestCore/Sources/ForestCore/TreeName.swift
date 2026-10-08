import Foundation

/// 자동으로 붙는 이름. 사용자가 고르거나 바꿀 수 없다.
public enum TreeName {
    static let adjectives = [
        "조용한", "느긋한", "새벽의", "단단한", "푸른", "따뜻한", "고요한", "바람 부는",
        "햇살 아래", "작은", "깊은", "너그러운", "맑은", "비 온 뒤의", "포근한", "곧은",
    ]

    static let trees = [
        "자작나무", "소나무", "은행나무", "단풍나무", "느티나무", "전나무", "벚나무", "올리브나무",
        "편백나무", "버드나무", "목련", "동백나무", "참나무", "팽나무", "주목", "향나무",
    ]

    /// 같은 seed에는 항상 같은 이름을 돌려준다.
    public static func make(seed: UUID) -> String {
        let bytes = withUnsafeBytes(of: seed.uuid) { Array($0) }
        let adjective = adjectives[Int(bytes[0]) % adjectives.count]
        let tree = trees[Int(bytes[1]) % trees.count]
        return "\(adjective) \(tree)"
    }
}

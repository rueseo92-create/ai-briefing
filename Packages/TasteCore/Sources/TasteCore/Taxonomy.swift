import Foundation

/// 웰니스 구역 여덟 개. 구역마다 우표가 있고, 엽서에는 그 구역의 우표가 붙는다.
public enum Domain: String, Codable, CaseIterable, Identifiable, Sendable {
    case rest
    case movement
    case food
    case breath
    case nature
    case senses
    case making
    case connection

    public var id: String { rawValue }

    /// 웰니스 영역
    public var title: String {
        switch self {
        case .rest: "잠과 쉼"
        case .movement: "움직임"
        case .food: "먹는 것"
        case .breath: "숨과 마음"
        case .nature: "자연"
        case .senses: "감각"
        case .making: "손과 만들기"
        case .connection: "사람과 연결"
        }
    }

    /// 우표 이름
    public var stampName: String {
        switch self {
        case .rest: "쉼터"
        case .movement: "오솔길"
        case .food: "열매밭"
        case .breath: "샘"
        case .nature: "큰 나무"
        case .senses: "꽃밭"
        case .making: "공방"
        case .connection: "모닥불"
        }
    }

    public var emoji: String {
        switch self {
        case .rest: "🛌"
        case .movement: "🥾"
        case .food: "🍑"
        case .breath: "💧"
        case .nature: "🌳"
        case .senses: "🌸"
        case .making: "🧶"
        case .connection: "🔥"
        }
    }
}

/// 좋았던(또는 별로였던) 이유. 추천은 분야가 아니라 이 이유를 따라간다.
public enum Tag: String, Codable, CaseIterable, Identifiable, Sendable {
    case quiet
    case novel
    case solo
    case together
    case making
    case moving
    case outdoors
    case slow
    case sensory
    case learning
    case pretty
    case refreshing

    public var id: String { rawValue }

    /// "○○ 좋았어요/별로였어요"
    public var title: String {
        switch self {
        case .quiet: "조용해서"
        case .novel: "처음 해 봐서"
        case .solo: "혼자라서"
        case .together: "함께라서"
        case .making: "뭔가 만들어서"
        case .moving: "몸을 움직여서"
        case .outdoors: "밖이라서"
        case .slow: "느긋해서"
        case .sensory: "감각이 깨어나서"
        case .learning: "새로 배워서"
        case .pretty: "예뻐서"
        case .refreshing: "기분이 바뀌어서"
        }
    }

    /// "○○ 사람"
    public var persona: String {
        switch self {
        case .quiet: "조용한 것에 마음이 가는"
        case .novel: "처음 해 보는 것에 설레는"
        case .solo: "혼자만의 시간으로 충전하는"
        case .together: "누군가와 함께일 때 빛나는"
        case .making: "손으로 무언가 만들 때 행복한"
        case .moving: "몸을 쓰며 머리를 비우는"
        case .outdoors: "바깥 공기가 필요한"
        case .slow: "느긋한 속도가 맞는"
        case .sensory: "맛, 향, 촉감에 예민한"
        case .learning: "배우는 순간을 즐기는"
        case .pretty: "예쁜 것을 알아보는"
        case .refreshing: "기분 전환이 빠른"
        }
    }
}

enum Hangul {
    /// 받침이 있으면 "이에요", 없으면 "예요". "오솔길이에요", "쉼터예요"
    static func copula(after word: String) -> String {
        guard let last = word.unicodeScalars.last, (0xAC00...0xD7A3).contains(last.value) else { return "이에요" }
        return (last.value - 0xAC00) % 28 == 0 ? "예요" : "이에요"
    }
}

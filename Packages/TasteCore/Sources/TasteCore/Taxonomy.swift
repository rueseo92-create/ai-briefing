import Foundation

/// 취향 지도의 지역. 실험은 하나의 지역에 속한다.
public enum Domain: String, Codable, CaseIterable, Identifiable, Sendable {
    case sound
    case taste
    case place
    case body
    case hands
    case people
    case mind
    case sight

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .sound: "소리"
        case .taste: "맛과 향"
        case .place: "공간"
        case .body: "몸"
        case .hands: "손"
        case .people: "사람"
        case .mind: "글과 생각"
        case .sight: "보는 것"
        }
    }

    public var emoji: String {
        switch self {
        case .sound: "🎧"
        case .taste: "☕️"
        case .place: "🗺️"
        case .body: "🏃"
        case .hands: "🧶"
        case .people: "🫂"
        case .mind: "📖"
        case .sight: "🖼️"
        }
    }
}

/// 좋았던(또는 별로였던) 이유. 추천은 분야가 아니라 이 이유를 따라간다.
/// 그래서 "조용해서 좋았던 카페" 다음에 "조용한 새벽 산책"이 나올 수 있다.
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

    /// 느낌을 고를 때 보이는 말. "○○해서 좋았어요/별로였어요"
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

    /// 취향 정리에서 쓰는 말. "○○ 사람"
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

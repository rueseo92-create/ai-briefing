import Foundation

/// 화면을 확인하기 위한 예시 광고 실험과 키트. 브랜드 이름은 모두 지어낸 것이고, 장소 좌표는 서울 안의 대략적인 점이다.
/// 실제로는 서버(CloudKit 공개 DB, 읽기 전용)에서 시·도 단위로 받아 와 Catalog와 합친다.
public enum SampleOffers {
    public static let all: [Experiment] = sponsored + kits

    private static func at(_ name: String, _ lat: Double, _ lon: Double) -> Place {
        .venue(Venue(name: name, coordinate: Coordinate(latitude: lat, longitude: lon)))
    }

    public static let sponsored: [Experiment] = [
        Experiment(
            id: "ad-sample-yoga", title: "처음 오는 사람을 위한 요가 수업", detail: "몸이 굳은 사람도 따라 할 수 있는 60분 기초 수업.",
            domain: .movement, tags: [.moving, .slow, .learning], minutes: 60, place: at("예시 요가 스튜디오 (마포)", 37.5560, 126.9220),
            cost: 25_000, sponsor: Sponsorship(brand: "예시 요가 스튜디오", benefit: "첫 수업 무료", priceAfterBenefit: 0, code: "POSTCARD0")
        ),
        Experiment(
            id: "ad-sample-tea", title: "찻집에서 계절 차 시음 코스", detail: "계절 차 세 가지를 천천히 마셔 봐요.",
            domain: .food, tags: [.quiet, .sensory, .slow], minutes: 60, place: at("예시 찻집 (종로)", 37.5760, 126.9860),
            cost: 18_000, sponsor: Sponsorship(brand: "예시 찻집", benefit: "시음 코스 40% 할인", priceAfterBenefit: 10_800, code: "TEA40")
        ),
        Experiment(
            id: "ad-sample-pottery", title: "동네 공방 물레 체험", detail: "처음 오는 사람을 위한 90분 수업. 만든 그릇은 구워서 보내 줘요.",
            domain: .making, tags: [.making, .sensory, .novel], minutes: 90, place: at("예시 공방 (성수)", 37.5445, 127.0560),
            cost: 50_000, sponsor: Sponsorship(brand: "예시 공방", benefit: "첫 수업 40% 할인", priceAfterBenefit: 30_000, code: "CLAY40")
        ),
        Experiment(
            id: "ad-sample-forest", title: "도심 숲 해설 산책", detail: "숲 해설가와 함께 걷는 90분.",
            domain: .nature, tags: [.outdoors, .learning, .quiet], minutes: 90, place: at("예시 숲 체험 (서울숲)", 37.5444, 127.0374),
            cost: 10_000, sponsor: Sponsorship(brand: "예시 숲 체험", benefit: "참가비 50% 할인", priceAfterBenefit: 5_000, code: "FOREST50")
        ),
    ]

    public static let kits: [Experiment] = [
        Experiment(
            id: "kit-sample-tea", title: "주말 아침 홈 티 시음", detail: "차 다섯 가지를 같은 방법으로 우려 비교해요.",
            domain: .food, tags: [.sensory, .quiet, .slow], minutes: 60, place: .home,
            kit: Kit(name: "홈 티 시음 키트", contents: ["잎차 5종 각 5g", "거름망", "맛 비교 카드"], price: 19_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-foot-spa", title: "토요일 밤 족욕", detail: "입욕 소금과 허브로 20분.",
            domain: .rest, tags: [.sensory, .slow, .refreshing], minutes: 30, place: .home,
            kit: Kit(name: "족욕 키트", contents: ["입욕 소금 3회분", "말린 허브", "족욕 가이드"], price: 15_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-embroidery", title: "토요일 오후 자수 한 판", detail: "도안을 따라 작은 꽃 하나를 수놓아요.",
            domain: .making, tags: [.making, .quiet, .pretty], minutes: 120, place: .home,
            kit: Kit(name: "자수 입문 키트", contents: ["수틀", "실 6색", "바늘", "도안 천"], price: 18_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-terrarium", title: "유리병 속 작은 숲 만들기", detail: "이끼와 돌로 책상 위 정원을 만들어요.",
            domain: .nature, tags: [.making, .pretty, .slow], minutes: 60, place: .home,
            kit: Kit(name: "테라리움 키트", contents: ["유리병", "이끼 3종", "흙과 자갈"], price: 32_000, leadDays: 3)
        ),
        Experiment(
            id: "kit-sample-walk-lunch", title: "산책 도시락 피크닉", detail: "도시락과 돗자리를 들고 공원으로.",
            domain: .nature, tags: [.outdoors, .slow, .sensory], minutes: 90, place: .nearby(roundTripMinutes: 20),
            kit: Kit(name: "피크닉 키트", contents: ["접이식 돗자리", "보냉 도시락 가방", "제철 과일 쿠폰"], price: 24_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-meditation", title: "향과 함께하는 저녁 명상", detail: "인센스 하나가 탈 동안 앉아 있어요.",
            domain: .breath, tags: [.quiet, .sensory, .slow], minutes: 20, place: .home,
            kit: Kit(name: "명상 키트", contents: ["인센스 10개", "홀더", "호흡 가이드 카드"], price: 12_000, leadDays: 2)
        ),
    ]
}

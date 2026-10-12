import Foundation

/// 화면을 확인하기 위한 예시 광고 실험과 키트. 브랜드 이름은 모두 지어낸 것이다.
/// 실제로는 서버(CloudKit 공개 DB)에서 받아 와 Catalog와 합친다.
public enum SampleOffers {
    public static let all: [Experiment] = sponsored + kits

    public static let sponsored: [Experiment] = [
        Experiment(
            id: "ad-sample-pottery", title: "동네 공방에서 물레 체험", detail: "처음 오는 사람을 위한 90분 수업. 만든 그릇은 구워서 보내 줘요.",
            domain: .hands, tags: [.making, .sensory, .novel], minutes: 90, place: .outside,
            sponsor: Sponsorship(brand: "예시 공방", benefit: "첫 수업 40% 할인", code: "TASTE40")
        ),
        Experiment(
            id: "ad-sample-climbing", title: "실내 클라이밍 1회 체험", detail: "장비 대여 포함. 강사가 처음부터 알려 줘요.",
            domain: .body, tags: [.moving, .novel, .learning], minutes: 90, place: .outside,
            sponsor: Sponsorship(brand: "예시 클라이밍", benefit: "체험권 1+1", code: "TASTE11")
        ),
        Experiment(
            id: "ad-sample-tea-house", title: "찻집에서 차 시음 코스", detail: "계절 차 세 가지를 천천히 마셔 봐요.",
            domain: .taste, tags: [.quiet, .sensory, .slow], minutes: 60, place: .outside,
            sponsor: Sponsorship(brand: "예시 찻집", benefit: "시음 코스 무료 업그레이드", code: "TASTETEA")
        ),
    ]

    public static let kits: [Experiment] = [
        Experiment(
            id: "kit-sample-drip", title: "주말 아침 핸드드립 입문", detail: "원두 세 가지를 같은 방법으로 내려 비교해요.",
            domain: .taste, tags: [.making, .sensory, .slow], minutes: 60, place: .home,
            kit: Kit(name: "핸드드립 입문 키트", contents: ["드리퍼와 필터 20장", "원두 3종 50g씩", "맛 비교 카드"], price: 29_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-embroidery", title: "토요일 오후 자수 한 판", detail: "도안을 따라 작은 꽃 하나를 수놓아요.",
            domain: .hands, tags: [.making, .quiet, .pretty], minutes: 120, place: .home,
            kit: Kit(name: "자수 입문 키트", contents: ["수틀", "실 6색", "바늘", "도안 천"], price: 18_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-terrarium", title: "유리병 속 작은 숲 만들기", detail: "이끼와 돌로 책상 위 정원을 만들어요.",
            domain: .hands, tags: [.making, .pretty, .slow], minutes: 60, place: .home,
            kit: Kit(name: "테라리움 키트", contents: ["유리병", "이끼 3종", "흙과 자갈", "미니 피규어"], price: 32_000, leadDays: 3)
        ),
        Experiment(
            id: "kit-sample-scent", title: "나만의 향 블렌딩", detail: "향료 다섯 가지를 섞어 내 향을 찾아요.",
            domain: .taste, tags: [.sensory, .making, .novel], minutes: 60, place: .home,
            kit: Kit(name: "향 블렌딩 키트", contents: ["향료 5종", "공병 2개", "시향지", "블렌딩 기록지"], price: 35_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-film", title: "일회용 필름카메라로 주말 기록", detail: "27장만 찍을 수 있어서 한 장 한 장 고르게 돼요.",
            domain: .sight, tags: [.pretty, .outdoors, .novel], minutes: 120, place: .outside,
            kit: Kit(name: "필름카메라 키트", contents: ["일회용 필름카메라", "현상 쿠폰"], price: 24_000, leadDays: 2)
        ),
        Experiment(
            id: "kit-sample-picnic-sketch", title: "공원에서 수채화 한 장", detail: "작은 팔레트 하나로 풍경을 그려요.",
            domain: .sight, tags: [.making, .outdoors, .slow], minutes: 90, place: .outside,
            kit: Kit(name: "야외 수채화 키트", contents: ["휴대용 팔레트", "워터브러시", "수채화 엽서 10장"], price: 27_000, leadDays: 2)
        ),
    ]
}

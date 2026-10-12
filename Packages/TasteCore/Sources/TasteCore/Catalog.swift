import Foundation

/// 기본 실험 카드. 어디서든, 하루 안에, 돈을 거의 안 들이고 할 수 있는 것만 넣었다.
/// id는 기록에 저장되니 바꾸지 않는다.
public enum Catalog {
    public static let all: [Experiment] = sound + taste + place + body + hands + people + mind + sight

    private static func e(
        _ id: String, _ title: String, _ detail: String,
        _ domain: Domain, _ tags: [Tag], _ minutes: Int, _ place: Experiment.Place
    ) -> Experiment {
        Experiment(id: id, title: title, detail: detail, domain: domain, tags: tags, minutes: minutes, place: place)
    }

    static let sound: [Experiment] = [
        e("sound-jazz-album", "가사 없는 재즈 앨범 하나 끝까지 듣기", "건너뛰지 않고 처음부터 끝까지. 다른 일은 하지 않아도 돼요.", .sound, [.quiet, .slow, .sensory], 45, .home),
        e("sound-field", "10분 동안 들리는 소리 모두 적기", "창문을 열고 들리는 소리를 하나씩 적어 봐요. 생각보다 많아요.", .sound, [.quiet, .sensory, .solo], 10, .home),
        e("sound-other-country", "처음 들어 보는 나라의 음악 듣기", "스트리밍에서 안 가 본 나라를 하나 골라 그 나라 인기곡을 들어요.", .sound, [.novel, .refreshing], 30, .home),
        e("sound-live-busking", "동네 버스킹이나 작은 공연 보기", "검색해서 가까운 무료 공연을 찾아 가 봐요.", .sound, [.outdoors, .together, .novel], 60, .outside),
        e("sound-humming-walk", "좋아하는 노래 흥얼거리며 걷기", "이어폰 없이, 내 목소리로만.", .sound, [.moving, .refreshing, .outdoors], 20, .outside),
        e("sound-asmr-rain", "빗소리 틀어 두고 낮잠 20분", "알람을 맞추고 빗소리에 몸을 맡겨요.", .sound, [.quiet, .slow, .solo], 20, .home),
        e("sound-old-playlist", "10년 전 즐겨 듣던 노래 다시 듣기", "그때의 내가 뭘 좋아했는지 떠올려 봐요.", .sound, [.slow, .refreshing, .solo], 30, .home),
        e("sound-instrument-app", "악기 앱으로 한 곡 따라 쳐 보기", "피아노 앱도 좋아요. 한 소절이면 충분해요.", .sound, [.learning, .making, .novel], 30, .home),
    ]

    static let taste: [Experiment] = [
        e("taste-hand-drip", "핸드드립 커피 내려 보기", "물 온도와 붓는 속도를 바꾸면 맛이 달라져요.", .taste, [.making, .sensory, .slow], 20, .home),
        e("taste-unknown-fruit", "처음 먹어 보는 과일 사 보기", "마트에서 이름만 알던 과일을 하나 골라요.", .taste, [.novel, .sensory], 15, .outside),
        e("taste-blind-tea", "차 세 가지 눈 감고 비교하기", "티백 세 개면 돼요. 어떤 게 제일 좋았는지 적어 봐요.", .taste, [.sensory, .quiet, .learning], 20, .home),
        e("taste-market-lunch", "전통시장에서 점심 먹기", "가 본 적 없는 시장이면 더 좋아요.", .taste, [.outdoors, .novel, .together], 60, .outside),
        e("taste-cook-new", "레시피 보고 처음 만드는 요리 하나", "어려운 것 말고 재료 다섯 개 이하로.", .taste, [.making, .learning], 60, .home),
        e("taste-scent-walk", "향 가게나 화장품 가게에서 향 다섯 가지 맡아 보기", "사지 않아도 돼요. 마음에 든 향의 이름만 적어 와요.", .taste, [.sensory, .novel, .pretty], 30, .outside),
        e("taste-slow-breakfast", "휴대폰 없이 아침 천천히 먹기", "한 입씩 맛을 느껴 봐요.", .taste, [.slow, .quiet, .sensory], 30, .home),
        e("taste-bakery-tour", "동네 빵집 두 곳의 같은 빵 비교하기", "크루아상이든 단팥빵이든 하나를 정해요.", .taste, [.outdoors, .sensory, .refreshing], 40, .outside),
    ]

    static let place: [Experiment] = [
        e("place-new-cafe", "처음 가 보는 카페에서 30분 앉아 있기", "할 일 없이 그냥 앉아 있어 봐요.", .place, [.quiet, .solo, .novel], 30, .outside),
        e("place-random-stop", "안 내려 본 정류장에서 내려 걷기", "버스나 지하철에서 늘 지나치던 곳.", .place, [.novel, .outdoors, .moving], 60, .outside),
        e("place-dawn-walk", "해 뜰 무렵 동네 한 바퀴", "같은 길도 새벽엔 달라요.", .place, [.quiet, .outdoors, .refreshing], 30, .outside),
        e("place-library", "도서관에서 한 시간 보내기", "책을 읽지 않아도 괜찮아요. 공기가 달라요.", .place, [.quiet, .slow, .solo], 60, .outside),
        e("place-rearrange", "방의 물건 세 개 자리 바꾸기", "의자 방향만 바꿔도 방이 새로워져요.", .place, [.refreshing, .making, .pretty], 20, .home),
        e("place-rooftop", "높은 곳에서 동네 내려다보기", "옥상, 언덕, 전망대 어디든.", .place, [.outdoors, .refreshing, .solo], 40, .outside),
        e("place-park-bench", "공원 벤치에서 사람 구경하기", "20분 동안 그냥 앉아 있어요.", .place, [.slow, .outdoors, .quiet], 20, .outside),
        e("place-bookstore", "독립서점 구경하기", "표지가 마음에 드는 책 하나를 기억해 와요.", .place, [.novel, .pretty, .quiet], 40, .outside),
    ]

    static let body: [Experiment] = [
        e("body-stretch-video", "15분 요가 영상 따라 하기", "잘 안 돼도 괜찮아요. 끝까지만.", .body, [.moving, .slow, .solo], 15, .home),
        e("body-climb-stairs", "계단으로만 다니는 하루", "엘리베이터 대신 계단.", .body, [.moving, .refreshing], 15, .outside),
        e("body-barefoot", "맨발로 흙이나 잔디 밟기", "공원 맨발길이 있다면 더 좋아요.", .body, [.sensory, .outdoors, .novel], 20, .outside),
        e("body-dance-alone", "방에서 노래 한 곡 춤추기", "아무도 안 봐요.", .body, [.moving, .refreshing, .solo], 5, .home),
        e("body-trial-class", "운동 체험 수업 하나 신청하기", "클라이밍, 필라테스, 복싱… 체험 수업이 있는 곳을 찾아봐요.", .body, [.novel, .moving, .learning], 60, .outside),
        e("body-cold-wash", "찬물로 세수하고 기분 적기", "딱 30초.", .body, [.sensory, .refreshing], 5, .home),
        e("body-long-walk", "만 보 채우는 산책", "목적지 없이 걷기.", .body, [.moving, .outdoors, .slow], 90, .outside),
        e("body-breath", "4초 들이쉬고 6초 내쉬기 5분", "앉아서 눈 감고.", .body, [.quiet, .slow, .solo], 5, .home),
    ]

    static let hands: [Experiment] = [
        e("hands-origami", "종이접기로 학 하나 접기", "영상 보고 천천히.", .hands, [.making, .quiet, .learning], 20, .home),
        e("hands-plant", "작은 화분에 씨앗 심기", "새싹이 나면 이 실험을 또 떠올리게 돼요.", .hands, [.making, .slow, .pretty], 20, .home),
        e("hands-letter", "손글씨로 편지 한 장 쓰기", "보내지 않아도 돼요.", .hands, [.making, .slow, .quiet], 30, .home),
        e("hands-sketch", "앞에 있는 물건 하나 따라 그리기", "컵이든 신발이든. 잘 그릴 필요 없어요.", .hands, [.making, .quiet, .solo], 20, .home),
        e("hands-pottery", "도자기 원데이 클래스", "흙을 만지는 감각이 꽤 오래 남아요.", .hands, [.making, .sensory, .novel], 120, .outside),
        e("hands-embroidery", "손수건에 이니셜 수놓기", "실과 바늘만 있으면 돼요.", .hands, [.making, .slow, .pretty], 60, .home),
        e("hands-fix", "고장 난 물건 하나 고쳐 보기", "단추 달기도 좋아요.", .hands, [.making, .learning, .solo], 30, .home),
        e("hands-collage", "잡지 오려서 콜라주 만들기", "마음에 드는 색만 모아 붙여요.", .hands, [.making, .pretty, .refreshing], 40, .home),
    ]

    static let people: [Experiment] = [
        e("people-call-old-friend", "오래 연락 안 한 사람에게 안부 묻기", "짧은 메시지 하나면 돼요.", .people, [.together, .refreshing], 10, .home),
        e("people-one-day-class", "모르는 사람들과 원데이 클래스 듣기", "주제는 뭐든 좋아요.", .people, [.together, .novel, .learning], 120, .outside),
        e("people-volunteer", "하루 봉사 활동", "동네 플로깅이나 유기견 산책 봉사.", .people, [.together, .outdoors, .moving], 120, .outside),
        e("people-ask-taste", "가까운 사람에게 요즘 빠진 것 물어보기", "그 사람이 추천한 걸 하나 해 봐요.", .people, [.together, .novel], 20, .home),
        e("people-meal-together", "누군가와 요리해서 같이 먹기", "한 명이면 충분해요.", .people, [.together, .making, .sensory], 90, .home),
        e("people-board-game", "보드게임 카페 가 보기", "처음 보는 게임으로.", .people, [.together, .novel, .refreshing], 90, .outside),
        e("people-compliment", "오늘 만난 사람에게 칭찬 하나 하기", "점원도 좋아요.", .people, [.together, .refreshing], 1, .outside),
        e("people-solo-dinner", "혼자 좋은 식당 가 보기", "혼밥이 아니라 나를 대접하는 저녁.", .people, [.solo, .sensory, .novel], 60, .outside),
    ]

    static let mind: [Experiment] = [
        e("mind-poem", "시집 한 권에서 시 세 편 읽기", "마음에 남는 한 줄을 적어 둬요.", .mind, [.quiet, .slow, .solo], 20, .home),
        e("mind-journal", "오늘 좋았던 것 세 가지 적기", "아주 작은 것도 괜찮아요.", .mind, [.quiet, .slow], 10, .home),
        e("mind-wiki-dive", "궁금했던 것 하나 깊게 찾아보기", "링크를 따라 30분만.", .mind, [.learning, .novel, .solo], 30, .home),
        e("mind-short-novel", "단편소설 한 편 읽기", "한 번에 끝까지.", .mind, [.quiet, .slow, .solo], 40, .home),
        e("mind-podcast-new", "안 듣던 분야의 팟캐스트 한 편", "과학, 역사, 건축… 낯선 쪽으로.", .mind, [.learning, .novel], 40, .home),
        e("mind-write-short", "300자짜리 짧은 글 쓰기", "주제: 요즘 나를 웃게 한 것.", .mind, [.making, .quiet, .solo], 20, .home),
        e("mind-language", "새 언어로 인사말 다섯 개 배우기", "발음까지 따라 해 봐요.", .mind, [.learning, .novel, .refreshing], 20, .home),
        e("mind-digital-off", "휴대폰 끄고 두 시간", "그동안 뭘 하게 되는지 지켜봐요.", .mind, [.quiet, .slow, .refreshing], 120, .home),
    ]

    static let sight: [Experiment] = [
        e("sight-gallery", "작은 갤러리 전시 보기", "무료 전시도 많아요.", .sight, [.pretty, .quiet, .novel], 60, .outside),
        e("sight-sunset", "노을 지는 시간 맞춰 하늘 보기", "일몰 시각을 찾아 10분 전에 나가요.", .sight, [.pretty, .outdoors, .slow], 20, .outside),
        e("sight-photo-walk", "한 가지 색만 골라 사진 열 장 찍기", "오늘은 초록만, 이런 식으로.", .sight, [.pretty, .outdoors, .making], 40, .outside),
        e("sight-old-movie", "흑백 영화 한 편 보기", "고전 하나 골라 끝까지.", .sight, [.slow, .novel, .solo], 100, .home),
        e("sight-stars", "불 끄고 밤하늘 10분 보기", "별 앱으로 별자리 하나 찾아봐요.", .sight, [.quiet, .outdoors, .learning], 10, .outside),
        e("sight-flower-shop", "꽃집에서 한 송이 사 오기", "이름을 모르는 꽃으로.", .sight, [.pretty, .novel, .sensory], 15, .outside),
        e("sight-architecture", "동네에서 예쁜 건물 세 곳 찾기", "창문, 문, 벽돌 무늬를 봐요.", .sight, [.pretty, .outdoors, .moving], 40, .outside),
        e("sight-picture-book", "그림책 한 권 천천히 보기", "도서관이나 서점에서.", .sight, [.pretty, .slow, .quiet], 20, .outside),
    ]
}

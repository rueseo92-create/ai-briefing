import Foundation

/// 기본 웰니스 실험 카드. 구역마다 10장. 절반 이상은 0원이다.
/// id는 기록에 저장되니 바꾸지 않는다.
public enum Catalog {
    public static let all: [Experiment] = rest + movement + food + breath + nature + senses + making + connection

    private static func e(
        _ id: String, _ title: String, _ detail: String, _ domain: Domain, _ tags: [Tag],
        _ minutes: Int, _ place: Place, _ cost: Int = 0, company: Bool = false
    ) -> Experiment {
        Experiment(id: id, title: title, detail: detail, domain: domain, tags: tags, minutes: minutes, place: place, cost: cost, needsCompany: company)
    }

    /// 동네 어디서나. 걸어서 다녀오는 시간.
    private static func near(_ minutes: Int) -> Place { .nearby(roundTripMinutes: minutes) }

    static let rest: [Experiment] = [
        e("rest-early-bed", "휴대폰 두고 30분 일찍 눕기", "불을 끄고 눈만 감고 있어도 괜찮아요.", .rest, [.quiet, .slow, .solo], 30, .home),
        e("rest-rain-nap", "빗소리 틀고 낮잠 20분", "알람을 맞추고 빗소리에 몸을 맡겨요.", .rest, [.quiet, .slow], 20, .home),
        e("rest-foot-bath", "따뜻한 물에 발 담그기 15분", "대야와 따뜻한 물이면 충분해요.", .rest, [.sensory, .slow, .refreshing], 15, .home),
        e("rest-window-sun", "창가에서 아침 햇볕 10분", "커피 없이, 햇볕만.", .rest, [.slow, .refreshing], 10, .home),
        e("rest-no-alarm", "알람 없이 일어나는 아침", "주말 하루, 몸이 깰 때까지.", .rest, [.slow, .quiet], 60, .home),
        e("rest-half-bath", "입욕제 풀고 반신욕", "물 온도는 손을 담가 따뜻한 정도로.", .rest, [.sensory, .slow], 30, .home, 5_000),
        e("rest-sauna", "동네 목욕탕이나 사우나 가기", "탕과 냉탕을 한 번씩.", .rest, [.sensory, .refreshing, .novel], 90, near(30), 10_000),
        e("rest-lavender", "잠들기 전 라벤더 향 맡기", "베개에 한 방울이면 돼요.", .rest, [.sensory, .quiet], 10, .home, 8_000),
        e("rest-do-nothing", "아무것도 안 하는 20분", "휴대폰도 책도 없이. 지루함도 느껴 봐요.", .rest, [.quiet, .slow, .solo], 20, .home),
        e("rest-park-lie", "공원 그늘에 누워 쉬기", "돗자리 하나 들고 나가요.", .rest, [.outdoors, .slow], 40, near(20)),
    ]

    static let movement: [Experiment] = [
        e("move-yoga-video", "15분 요가 영상 따라 하기", "잘 안 돼도 끝까지만.", .movement, [.moving, .slow, .solo], 15, .home),
        e("move-barefoot", "맨발로 흙길 걷기", "공원 맨발길이 있다면 더 좋아요.", .movement, [.sensory, .outdoors, .novel], 30, near(30)),
        e("move-stairs", "계단으로만 다니는 하루", "엘리베이터 대신 계단.", .movement, [.moving, .refreshing], 15, .home),
        e("move-dance", "방에서 노래 한 곡 춤추기", "아무도 안 봐요.", .movement, [.moving, .refreshing, .solo], 5, .home),
        e("move-evening-walk", "저녁 먹고 동네 30분 걷기", "목적지 없이 한 바퀴.", .movement, [.moving, .outdoors, .slow], 30, near(0)),
        e("move-trial-class", "운동 체험 수업 하나 해 보기", "클라이밍, 필라테스, 복싱… 체험 수업이 있는 곳으로.", .movement, [.novel, .moving, .learning], 60, near(40), 15_000),
        e("move-desk-stretch", "일하다 5분 스트레칭", "목, 어깨, 손목 순서로.", .movement, [.moving, .refreshing], 5, .home),
        e("move-bike", "공유 자전거로 한 시간", "천변이나 공원 길로.", .movement, [.moving, .outdoors, .refreshing], 60, near(20), 2_000),
        e("move-hill", "동네 뒷산 오르기", "정상이 아니어도 괜찮아요.", .movement, [.moving, .outdoors, .quiet], 90, near(40)),
        e("move-badminton", "누군가와 배드민턴 치기", "공원에서 30분.", .movement, [.together, .moving, .outdoors], 40, near(20), company: true),
    ]

    static let food: [Experiment] = [
        e("food-new-fruit", "처음 먹어 보는 제철 과일", "이름만 알던 과일 하나.", .food, [.novel, .sensory], 15, near(20), 5_000),
        e("food-slow-breakfast", "휴대폰 없이 아침 천천히 먹기", "한 입씩 맛을 느껴 봐요.", .food, [.slow, .quiet, .sensory], 30, .home),
        e("food-drip", "드립백 커피 천천히 내리기", "물을 세 번에 나눠 부어요.", .food, [.making, .sensory, .slow], 20, .home, 2_000),
        e("food-market-lunch", "전통시장에서 점심 먹기", "가 본 적 없는 시장이면 더 좋아요.", .food, [.outdoors, .novel, .sensory], 60, near(40), 10_000),
        e("food-cook-new", "처음 만드는 요리 하나", "재료 다섯 개 이하로.", .food, [.making, .learning], 60, .home, 10_000),
        e("food-tea-blind", "차 세 가지 눈 감고 비교하기", "티백 세 개면 돼요. 어떤 게 좋았는지 적어요.", .food, [.sensory, .quiet, .learning], 20, .home, 5_000),
        e("food-green-meal", "한 끼를 채소로만", "샐러드가 아니어도 돼요. 나물 비빔밥도.", .food, [.novel, .refreshing], 30, .home, 5_000),
        e("food-bakery-two", "빵집 두 곳의 같은 빵 비교하기", "크루아상이든 단팥빵이든 하나를 정해요.", .food, [.sensory, .outdoors], 40, near(30), 8_000),
        e("food-picnic", "도시락 싸서 공원에서 먹기", "김밥 한 줄도 좋아요.", .food, [.outdoors, .slow, .making], 60, near(20), 5_000),
        e("food-cook-together", "누군가와 요리해서 같이 먹기", "한 명이면 충분해요.", .food, [.together, .making, .sensory], 90, .home, 15_000, company: true),
    ]

    static let breath: [Experiment] = [
        e("breath-4-6", "4초 들이쉬고 6초 내쉬기 5분", "앉아서 눈 감고.", .breath, [.quiet, .slow, .solo], 5, .home),
        e("breath-three-good", "오늘 좋았던 것 세 가지 적기", "아주 작은 것도 괜찮아요.", .breath, [.quiet, .slow], 10, .home),
        e("breath-digital-off", "휴대폰 끄고 두 시간", "그동안 뭘 하게 되는지 지켜봐요.", .breath, [.quiet, .slow, .refreshing], 120, .home),
        e("breath-poem", "시 세 편 읽기", "마음에 남는 한 줄을 적어 둬요.", .breath, [.quiet, .slow, .solo], 20, .home),
        e("breath-future-letter", "한 달 뒤의 나에게 편지 쓰기", "봉투에 넣어 날짜를 적어 둬요.", .breath, [.making, .quiet, .solo], 20, .home),
        e("breath-guided", "10분 명상 따라 하기", "무료 명상 영상 하나 골라요.", .breath, [.quiet, .learning], 10, .home),
        e("breath-worry-fold", "걱정 적고 접어 두기", "종이에 적고 반으로 접어 서랍에.", .breath, [.quiet, .refreshing], 10, .home),
        e("breath-quiet-yard", "절이나 성당의 조용한 마당 걷기", "누구나 들어갈 수 있는 곳으로.", .breath, [.quiet, .outdoors, .novel], 40, near(60)),
        e("breath-candle", "촛불 하나 켜고 10분 바라보기", "불이 흔들리는 걸 지켜봐요.", .breath, [.quiet, .sensory, .slow], 10, .home, 3_000),
        e("breath-library", "도서관에서 한 시간", "책을 안 읽어도 괜찮아요. 공기가 달라요.", .breath, [.quiet, .slow, .solo], 60, near(30)),
    ]

    static let nature: [Experiment] = [
        e("nature-dawn-walk", "해 뜰 무렵 동네 산책", "같은 길도 새벽엔 달라요.", .nature, [.quiet, .outdoors, .refreshing], 30, near(0)),
        e("nature-seed", "작은 화분에 씨앗 심기", "새싹이 나면 이 엽서가 떠오를 거예요.", .nature, [.making, .slow, .pretty], 20, .home, 3_000),
        e("nature-sunset", "노을 시간 맞춰 하늘 보기", "일몰 10분 전에 나가요.", .nature, [.pretty, .outdoors, .slow], 20, near(10)),
        e("nature-stars", "불 끄고 밤하늘 10분", "별 앱으로 별자리 하나 찾아봐요.", .nature, [.quiet, .outdoors, .learning], 10, near(0)),
        e("nature-tree-name", "동네 큰 나무 하나 이름 알아보기", "사진을 찍고 식물 이름 찾기로.", .nature, [.outdoors, .learning, .novel], 30, near(20)),
        e("nature-arboretum", "수목원이나 식물원 가기", "계절 꽃이 피는 곳으로.", .nature, [.outdoors, .pretty, .slow], 120, near(120), 5_000),
        e("nature-leaves", "모양이 다른 잎 다섯 장 줍기", "집에 와서 책 사이에 끼워 둬요.", .nature, [.outdoors, .pretty, .making], 30, near(20)),
        e("nature-stream", "천변이나 강 따라 걷기", "물소리가 들리는 쪽으로.", .nature, [.outdoors, .moving, .quiet], 60, near(30)),
        e("nature-forest-hour", "숲길에서 한 시간 천천히", "빠르게 걷지 말고, 멈춰서 들어요.", .nature, [.outdoors, .quiet, .slow], 60, near(90)),
        e("nature-one-flower", "꽃집에서 한 송이 사 오기", "이름을 모르는 꽃으로.", .nature, [.pretty, .novel, .sensory], 15, near(20), 5_000),
    ]

    static let senses: [Experiment] = [
        e("senses-scent-five", "향 가게에서 향 다섯 가지 맡기", "사지 않아도 돼요. 마음에 든 이름만 적어 와요.", .senses, [.sensory, .novel, .pretty], 30, near(40)),
        e("senses-album", "가사 없는 앨범 하나 끝까지 듣기", "건너뛰지 않고 처음부터 끝까지.", .senses, [.quiet, .slow, .sensory], 45, .home),
        e("senses-sound-list", "10분 동안 들리는 소리 다 적기", "창문을 열고 하나씩.", .senses, [.quiet, .sensory, .solo], 10, .home),
        e("senses-gallery", "작은 갤러리 전시 보기", "무료 전시도 많아요.", .senses, [.pretty, .quiet, .novel], 60, near(60)),
        e("senses-one-color", "한 가지 색만 골라 사진 열 장", "오늘은 초록만, 이런 식으로.", .senses, [.pretty, .outdoors, .making], 40, near(0)),
        e("senses-texture", "맨손으로 질감 다섯 가지 느끼기", "나무, 천, 돌, 물, 흙.", .senses, [.sensory, .quiet, .novel], 10, .home),
        e("senses-world-music", "처음 듣는 나라의 음악 듣기", "안 가 본 나라 하나를 골라요.", .senses, [.novel, .refreshing], 30, .home),
        e("senses-small-gig", "작은 공연 보기", "동네 소극장이나 라이브 카페.", .senses, [.novel, .sensory, .outdoors], 90, near(60), 20_000),
        e("senses-old-film", "흑백 영화 한 편 보기", "고전 하나를 끝까지.", .senses, [.slow, .novel, .solo], 100, .home),
        e("senses-picture-book", "그림책 한 권 천천히 보기", "도서관이나 서점에서.", .senses, [.pretty, .slow, .quiet], 20, near(30)),
    ]

    static let making: [Experiment] = [
        e("making-crane", "종이학 하나 접기", "영상 보고 천천히.", .making, [.making, .quiet, .learning], 20, .home),
        e("making-letter", "손편지 한 장 쓰기", "보내지 않아도 돼요.", .making, [.making, .slow, .quiet], 30, .home),
        e("making-sketch", "앞에 있는 물건 하나 따라 그리기", "컵이든 신발이든. 잘 그릴 필요 없어요.", .making, [.making, .quiet, .solo], 20, .home),
        e("making-pottery", "도자기 원데이 클래스", "흙을 만지는 감각이 오래 남아요.", .making, [.making, .sensory, .novel], 120, near(60), 40_000),
        e("making-embroidery", "손수건에 이니셜 수놓기", "실과 바늘만 있으면 돼요.", .making, [.making, .slow, .pretty], 60, .home, 8_000),
        e("making-fix", "고장 난 물건 하나 고쳐 보기", "단추 달기도 좋아요.", .making, [.making, .learning, .solo], 30, .home),
        e("making-collage", "잡지 오려서 콜라주 만들기", "마음에 드는 색만 모아 붙여요.", .making, [.making, .pretty, .refreshing], 40, .home),
        e("making-candle", "캔들 만들기 클래스", "향을 직접 골라 섞어요.", .making, [.making, .sensory, .pretty], 90, near(60), 30_000),
        e("making-bookmark", "말린 잎으로 책갈피 만들기", "투명 테이프로 감싸면 끝.", .making, [.making, .pretty, .slow], 30, .home),
        e("making-one-bar", "악기 앱으로 한 소절 쳐 보기", "피아노 앱도 좋아요.", .making, [.learning, .making, .novel], 30, .home),
    ]

    static let connection: [Experiment] = [
        e("conn-old-friend", "오래 연락 안 한 사람에게 안부 묻기", "짧은 메시지 하나면 돼요.", .connection, [.together, .refreshing], 10, .home),
        e("conn-ask-taste", "가까운 사람에게 요즘 빠진 것 묻기", "그 사람이 추천한 걸 하나 해 봐요.", .connection, [.together, .novel], 20, .home),
        e("conn-compliment", "오늘 만난 사람에게 칭찬 하나", "점원도 좋아요.", .connection, [.together, .refreshing], 5, near(0)),
        e("conn-board-game", "보드게임 카페 가 보기", "처음 보는 게임으로.", .connection, [.together, .novel, .refreshing], 90, near(40), 10_000, company: true),
        e("conn-plogging", "동네 플로깅 하루", "봉투 하나 들고 걸으며 줍기.", .connection, [.together, .outdoors, .moving], 60, near(0)),
        e("conn-solo-dinner", "혼자 좋은 식당 가 보기", "혼밥이 아니라 나를 대접하는 저녁.", .connection, [.solo, .sensory, .novel], 60, near(40), 25_000),
        e("conn-walk-talk", "누군가와 걸으며 이야기하기", "마주 앉는 것보다 편해요.", .connection, [.together, .outdoors, .moving], 40, near(0), company: true),
        e("conn-real-postcard", "친구에게 진짜 엽서 보내기", "우체국 가는 길도 실험이에요.", .connection, [.together, .making, .slow], 20, near(20), 2_000),
        e("conn-old-photos", "가족과 옛날 사진 같이 보기", "사진마다 이야기 하나씩.", .connection, [.together, .slow], 30, .home, company: true),
        e("conn-class-chat", "원데이 클래스에서 옆 사람과 이야기하기", "주제는 뭐든 좋아요.", .connection, [.together, .novel, .learning], 120, near(60), 30_000),
    ]
}

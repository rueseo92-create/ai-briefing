import Foundation

/// 기본 웰니스 실험 카드. 구역마다 10장 남짓. 절반 이상은 0원이다.
/// 공원·한강·도서관처럼 실제로 있어야 하는 곳은 `.find`로 두고, 지도에서 동네 근처에 있을 때만 권한다.
/// id는 기록에 저장되니 바꾸지 않는다.
public enum Catalog {
    public static let all: [Experiment] = rest + movement + food + breath + nature + senses + making + connection + more

    private static func e(
        _ id: String, _ title: String, _ detail: String, _ domain: Domain, _ tags: [Tag],
        _ minutes: Int, _ place: Place, _ cost: Int = 0, company: Bool = false, seasons: [Season]? = nil
    ) -> Experiment {
        Experiment(id: id, title: title, detail: detail, domain: domain, tags: tags, minutes: minutes, place: place, cost: cost, needsCompany: company, seasons: seasons)
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
        e("rest-sauna", "동네 목욕탕이나 사우나 가기", "탕과 냉탕을 한 번씩.", .rest, [.sensory, .refreshing, .novel], 90, .find(.sauna), 10_000),
        e("rest-lavender", "잠들기 전 라벤더 향 맡기", "베개에 한 방울이면 돼요.", .rest, [.sensory, .quiet], 10, .home, 8_000),
        e("rest-do-nothing", "아무것도 안 하는 20분", "휴대폰도 책도 없이. 지루함도 느껴 봐요.", .rest, [.quiet, .slow, .solo], 20, .home),
        e("rest-park-lie", "공원 그늘에 누워 쉬기", "돗자리 하나 들고 나가요.", .rest, [.outdoors, .slow], 40, .find(.park)),
    ]

    static let movement: [Experiment] = [
        e("move-yoga-video", "15분 요가 영상 따라 하기", "잘 안 돼도 끝까지만.", .movement, [.moving, .slow, .solo], 15, .home),
        e("move-barefoot", "맨발길이나 황톳길 걷기", "근처에 맨발길이 있을 때만 나오는 실험이에요.", .movement, [.sensory, .outdoors, .novel], 30, .find(.barefootPath)),
        e("move-stairs", "계단으로만 다니는 하루", "엘리베이터 대신 계단.", .movement, [.moving, .refreshing], 15, .home),
        e("move-dance", "방에서 노래 한 곡 춤추기", "아무도 안 봐요.", .movement, [.moving, .refreshing, .solo], 5, .home),
        e("move-evening-walk", "저녁 먹고 동네 30분 걷기", "목적지 없이 한 바퀴.", .movement, [.moving, .outdoors, .slow], 30, near(0)),
        e("move-trial-class", "운동 체험 수업 하나 해 보기", "클라이밍, 필라테스, 복싱… 체험 수업이 있는 곳으로.", .movement, [.novel, .moving, .learning], 60, .find(.fitness), 15_000),
        e("move-desk-stretch", "일하다 5분 스트레칭", "목, 어깨, 손목 순서로.", .movement, [.moving, .refreshing], 5, .home),
        e("move-bike", "한강·천변에서 자전거 한 시간", "공유 자전거를 빌려 물길을 따라.", .movement, [.moving, .outdoors, .refreshing], 60, .find(.waterside), 2_000),
        e("move-hill", "동네 뒷산 오르기", "정상이 아니어도 괜찮아요.", .movement, [.moving, .outdoors, .quiet], 90, .find(.trail)),
        e("move-badminton", "누군가와 배드민턴 치기", "공원에서 30분.", .movement, [.together, .moving, .outdoors], 40, .find(.park), company: true),
    ]

    static let food: [Experiment] = [
        e("food-new-fruit", "처음 먹어 보는 제철 과일", "이름만 알던 과일 하나.", .food, [.novel, .sensory], 15, .find(.grocery), 5_000),
        e("food-slow-breakfast", "휴대폰 없이 아침 천천히 먹기", "한 입씩 맛을 느껴 봐요.", .food, [.slow, .quiet, .sensory], 30, .home),
        e("food-drip", "드립백 커피 천천히 내리기", "물을 세 번에 나눠 부어요.", .food, [.making, .sensory, .slow], 20, .home, 2_000),
        e("food-market-lunch", "전통시장에서 점심 먹기", "가 본 적 없는 시장이면 더 좋아요.", .food, [.outdoors, .novel, .sensory], 60, .find(.market), 10_000),
        e("food-cook-new", "처음 만드는 요리 하나", "재료 다섯 개 이하로.", .food, [.making, .learning], 60, .home, 10_000),
        e("food-tea-blind", "차 세 가지 눈 감고 비교하기", "티백 세 개면 돼요. 어떤 게 좋았는지 적어요.", .food, [.sensory, .quiet, .learning], 20, .home, 5_000),
        e("food-green-meal", "한 끼를 채소로만", "샐러드가 아니어도 돼요. 나물 비빔밥도.", .food, [.novel, .refreshing], 30, .home, 5_000),
        e("food-bakery-two", "빵집 두 곳의 같은 빵 비교하기", "크루아상이든 단팥빵이든 하나를 정해요.", .food, [.sensory, .outdoors], 40, .find(.bakery), 8_000),
        e("food-picnic", "도시락 싸서 공원에서 먹기", "김밥 한 줄도 좋아요.", .food, [.outdoors, .slow, .making], 60, .find(.park), 5_000),
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
        e("breath-quiet-yard", "절이나 성당의 조용한 마당 걷기", "누구나 들어갈 수 있는 곳으로.", .breath, [.quiet, .outdoors, .novel], 40, .find(.quietYard)),
        e("breath-candle", "촛불 하나 켜고 10분 바라보기", "불이 흔들리는 걸 지켜봐요.", .breath, [.quiet, .sensory, .slow], 10, .home, 3_000),
        e("breath-library", "도서관에서 한 시간", "책을 안 읽어도 괜찮아요. 공기가 달라요.", .breath, [.quiet, .slow, .solo], 60, .find(.library)),
    ]

    static let nature: [Experiment] = [
        e("nature-dawn-walk", "해 뜰 무렵 동네 산책", "같은 길도 새벽엔 달라요.", .nature, [.quiet, .outdoors, .refreshing], 30, near(0)),
        e("nature-seed", "작은 화분에 씨앗 심기", "새싹이 나면 이 엽서가 떠오를 거예요.", .nature, [.making, .slow, .pretty], 20, .home, 3_000),
        e("nature-sunset", "노을 시간 맞춰 하늘 보기", "일몰 10분 전에 나가요.", .nature, [.pretty, .outdoors, .slow], 20, near(10)),
        e("nature-stars", "불 끄고 밤하늘 10분", "별 앱으로 별자리 하나 찾아봐요.", .nature, [.quiet, .outdoors, .learning], 10, near(0)),
        e("nature-tree-name", "동네 큰 나무 하나 이름 알아보기", "사진을 찍고 식물 이름 찾기로.", .nature, [.outdoors, .learning, .novel], 30, .find(.park)),
        e("nature-arboretum", "수목원이나 식물원 가기", "계절 꽃이 피는 곳으로.", .nature, [.outdoors, .pretty, .slow], 120, .find(.arboretum), 5_000),
        e("nature-leaves", "모양이 다른 잎 다섯 장 줍기", "집에 와서 책 사이에 끼워 둬요.", .nature, [.outdoors, .pretty, .making], 30, .find(.park)),
        e("nature-stream", "한강이나 천변 따라 걷기", "물소리가 들리는 쪽으로. 가장 가까운 한강공원이나 천변 산책로를 찾아 드려요.", .nature, [.outdoors, .moving, .quiet], 60, .find(.waterside)),
        e("nature-forest-hour", "숲길에서 한 시간 천천히", "빠르게 걷지 말고, 멈춰서 들어요.", .nature, [.outdoors, .quiet, .slow], 60, .find(.trail)),
        e("nature-one-flower", "꽃집에서 한 송이 사 오기", "이름을 모르는 꽃으로.", .nature, [.pretty, .novel, .sensory], 15, .find(.flowerShop), 5_000),
    ]

    static let senses: [Experiment] = [
        e("senses-scent-five", "향 가게에서 향 다섯 가지 맡기", "사지 않아도 돼요. 마음에 든 이름만 적어 와요.", .senses, [.sensory, .novel, .pretty], 30, .find(.scentShop)),
        e("senses-album", "가사 없는 앨범 하나 끝까지 듣기", "건너뛰지 않고 처음부터 끝까지.", .senses, [.quiet, .slow, .sensory], 45, .home),
        e("senses-sound-list", "10분 동안 들리는 소리 다 적기", "창문을 열고 하나씩.", .senses, [.quiet, .sensory, .solo], 10, .home),
        e("senses-gallery", "작은 갤러리 전시 보기", "무료 전시도 많아요.", .senses, [.pretty, .quiet, .novel], 60, .find(.gallery)),
        e("senses-one-color", "한 가지 색만 골라 사진 열 장", "오늘은 초록만, 이런 식으로.", .senses, [.pretty, .outdoors, .making], 40, near(0)),
        e("senses-texture", "맨손으로 질감 다섯 가지 느끼기", "나무, 천, 돌, 물, 흙.", .senses, [.sensory, .quiet, .novel], 10, .home),
        e("senses-world-music", "처음 듣는 나라의 음악 듣기", "안 가 본 나라 하나를 골라요.", .senses, [.novel, .refreshing], 30, .home),
        e("senses-small-gig", "작은 공연 보기", "동네 소극장이나 라이브 카페.", .senses, [.novel, .sensory, .outdoors], 90, .find(.liveVenue), 20_000),
        e("senses-old-film", "흑백 영화 한 편 보기", "고전 하나를 끝까지.", .senses, [.slow, .novel, .solo], 100, .home),
        e("senses-picture-book", "그림책 한 권 천천히 보기", "도서관이나 서점에서.", .senses, [.pretty, .slow, .quiet], 20, .find(.bookstore)),
    ]

    static let making: [Experiment] = [
        e("making-crane", "종이학 하나 접기", "영상 보고 천천히.", .making, [.making, .quiet, .learning], 20, .home),
        e("making-letter", "손편지 한 장 쓰기", "보내지 않아도 돼요.", .making, [.making, .slow, .quiet], 30, .home),
        e("making-sketch", "앞에 있는 물건 하나 따라 그리기", "컵이든 신발이든. 잘 그릴 필요 없어요.", .making, [.making, .quiet, .solo], 20, .home),
        e("making-pottery", "도자기 원데이 클래스", "흙을 만지는 감각이 오래 남아요.", .making, [.making, .sensory, .novel], 120, .find(.craftStudio), 40_000),
        e("making-embroidery", "손수건에 이니셜 수놓기", "실과 바늘만 있으면 돼요.", .making, [.making, .slow, .pretty], 60, .home, 8_000),
        e("making-fix", "고장 난 물건 하나 고쳐 보기", "단추 달기도 좋아요.", .making, [.making, .learning, .solo], 30, .home),
        e("making-collage", "잡지 오려서 콜라주 만들기", "마음에 드는 색만 모아 붙여요.", .making, [.making, .pretty, .refreshing], 40, .home),
        e("making-candle", "캔들 만들기 클래스", "향을 직접 골라 섞어요.", .making, [.making, .sensory, .pretty], 90, .find(.craftStudio), 30_000),
        e("making-bookmark", "말린 잎으로 책갈피 만들기", "투명 테이프로 감싸면 끝.", .making, [.making, .pretty, .slow], 30, .home),
        e("making-one-bar", "악기 앱으로 한 소절 쳐 보기", "피아노 앱도 좋아요.", .making, [.learning, .making, .novel], 30, .home),
    ]

    static let connection: [Experiment] = [
        e("conn-old-friend", "오래 연락 안 한 사람에게 안부 묻기", "짧은 메시지 하나면 돼요.", .connection, [.together, .refreshing], 10, .home),
        e("conn-ask-taste", "가까운 사람에게 요즘 빠진 것 묻기", "그 사람이 추천한 걸 하나 해 봐요.", .connection, [.together, .novel], 20, .home),
        e("conn-compliment", "오늘 만난 사람에게 칭찬 하나", "점원도 좋아요.", .connection, [.together, .refreshing], 5, near(0)),
        e("conn-board-game", "보드게임 카페 가 보기", "처음 보는 게임으로.", .connection, [.together, .novel, .refreshing], 90, .find(.boardGameCafe), 10_000, company: true),
        e("conn-plogging", "동네 플로깅 하루", "봉투 하나 들고 걸으며 줍기.", .connection, [.together, .outdoors, .moving], 60, near(0)),
        e("conn-solo-dinner", "혼자 좋은 식당 가 보기", "혼밥이 아니라 나를 대접하는 저녁.", .connection, [.solo, .sensory, .novel], 60, near(40), 25_000),
        e("conn-walk-talk", "누군가와 걸으며 이야기하기", "마주 앉는 것보다 편해요.", .connection, [.together, .outdoors, .moving], 40, near(0), company: true),
        e("conn-real-postcard", "친구에게 진짜 엽서 보내기", "우체국 가는 길도 실험이에요.", .connection, [.together, .making, .slow], 20, .find(.postOffice), 2_000),
        e("conn-old-photos", "가족과 옛날 사진 같이 보기", "사진마다 이야기 하나씩.", .connection, [.together, .slow], 30, .home, company: true),
        e("conn-campfire", "모닥불 앞에서 불멍 하기", "캠핑장이나 불멍 카페에서. 불을 보며 이야기하거나 그냥 앉아 있어요.", .connection, [.together, .slow, .outdoors], 90, .find(.campfire), 20_000),
        e("conn-class-chat", "원데이 클래스에서 옆 사람과 이야기하기", "주제는 뭐든 좋아요.", .connection, [.together, .novel, .learning], 120, .find(.craftStudio), 30_000),
    ]

    /// 두 번째 묶음. 계절 카드는 그 계절에만 나온다.
    static let more: [Experiment] = [
        e("rest-bedtime-tea", "잠들기 전 따뜻한 차 한 잔", "카페인 없는 차로. 휴대폰은 다른 방에.", .rest, [.slow, .quiet, .sensory], 15, .home),
        e("rest-bed-stretch", "잠들기 전 침대에서 스트레칭 10분", "누운 채로 할 수 있는 동작만.", .rest, [.slow, .quiet], 10, .home),
        e("rest-fresh-sheets", "침구 빨아서 새로 깔고 자기", "갓 마른 이불 냄새를 맡아 봐요.", .rest, [.refreshing, .sensory], 40, .home),
        e("rest-warm-pack", "따뜻한 찜질팩 올리고 15분", "목이나 배 위에.", .rest, [.sensory, .slow], 15, .home, 3_000, seasons: [.winter]),
        e("rest-summer-shade", "한여름 오후 나무 그늘에서 쉬기", "가장 더운 시간에 그늘 아래로.", .rest, [.outdoors, .slow], 30, .find(.park), seasons: [.summer]),

        e("move-jump-rope", "줄넘기 100번", "나눠서 해도 돼요.", .movement, [.moving, .refreshing], 10, near(0), 5_000),
        e("move-plank", "플랭크 30초 세 번", "자세 영상 하나 보고.", .movement, [.moving, .learning], 5, .home),
        e("move-cherry-walk", "벚꽃길 걷기", "꽃이 진 길도 괜찮아요.", .movement, [.outdoors, .pretty, .moving], 40, .find(.park), seasons: [.spring]),
        e("move-autumn-hike", "단풍 든 산길 걷기", "정상 말고 단풍이 예쁜 데까지만.", .movement, [.outdoors, .moving, .pretty], 120, .find(.trail), seasons: [.autumn]),
        e("move-snow-walk", "눈 온 날 발자국 남기며 걷기", "미끄럽지 않은 길로.", .movement, [.outdoors, .novel, .refreshing], 20, near(0), seasons: [.winter]),

        e("food-season-side", "제철 채소 하나로 반찬 만들기", "시장이나 마트에서 가장 싼 채소가 제철이에요.", .food, [.making, .sensory], 30, .home, 5_000),
        e("food-spring-greens", "봄나물 비빔밥", "냉이, 달래, 두릅 중 하나만이라도.", .food, [.sensory, .novel], 30, .home, 8_000, seasons: [.spring]),
        e("food-watermelon-bowl", "수박 화채 만들기", "얼음 넉넉히.", .food, [.making, .refreshing], 20, .home, 10_000, seasons: [.summer]),
        e("food-roasted-snack", "군밤이나 군고구마 사 먹기", "길에서 따뜻할 때 바로.", .food, [.sensory, .outdoors], 15, near(20), 5_000, seasons: [.autumn, .winter]),
        e("food-warm-cup", "찻잔 데워서 차 천천히 마시기", "잔에 뜨거운 물을 먼저 부었다가 버려요.", .food, [.slow, .quiet, .learning], 20, .home),

        e("breath-body-scan", "누워서 발끝부터 몸 훑기 10분", "힘이 들어간 곳을 하나씩 풀어요.", .breath, [.quiet, .slow, .solo], 10, .home),
        e("breath-thanks", "고마운 사람에게 짧은 메시지", "이유 한 줄과 함께.", .breath, [.together, .refreshing], 5, .home),
        e("breath-rain-window", "창가에서 빗소리 15분 듣기", "비 오는 날에만 할 수 있는 실험이에요.", .breath, [.quiet, .sensory], 15, .home),
        e("breath-walking", "천천히 걷기 명상 10분", "발바닥이 땅에 닿는 느낌에만 집중해요.", .breath, [.quiet, .slow, .outdoors], 10, .find(.park)),
        e("breath-year-letter", "올해의 나에게 편지 쓰기", "잘한 것 세 가지부터.", .breath, [.making, .quiet, .slow], 30, .home, seasons: [.winter]),

        e("nature-blossom", "벚꽃 구경", "바람 부는 날이면 꽃비가 내려요.", .nature, [.pretty, .outdoors], 60, .find(.park), seasons: [.spring]),
        e("nature-river-breeze", "한강이나 천변에서 저녁 바람 맞기", "해 지고 나서 시원할 때.", .nature, [.outdoors, .slow, .refreshing], 60, .find(.waterside), seasons: [.summer]),
        e("nature-maple-photo", "단풍 사진 한 장", "빛이 비스듬한 오후에.", .nature, [.pretty, .outdoors], 30, .find(.park), seasons: [.autumn]),
        e("nature-first-snow", "첫눈 오는 날 밖에 나가 보기", "5분이라도.", .nature, [.novel, .outdoors, .refreshing], 15, near(0), seasons: [.winter]),
        e("nature-clouds", "구름 모양 세 개 찾기", "누워서 보면 더 잘 보여요.", .nature, [.slow, .quiet, .outdoors], 10, near(0)),

        e("senses-perfume-strips", "시향지로 향수 세 가지 비교하기", "첫 향, 10분 뒤 향이 달라요.", .senses, [.sensory, .novel], 30, .find(.scentShop)),
        e("senses-request-song", "라이브 공연장에서 한 곡 듣기", "모르는 가수여도 좋아요.", .senses, [.sensory, .novel], 60, .find(.liveVenue), 10_000),
        e("senses-dark-tea", "불 끄고 차 마시기", "눈을 쓰지 않으면 맛이 달라져요.", .senses, [.sensory, .quiet, .novel], 15, .home),
        e("senses-one-room", "미술관 한 전시실만 천천히", "한 작품 앞에서 3분.", .senses, [.learning, .quiet, .pretty], 60, .find(.gallery)),
        e("senses-autumn-smell", "가을 냄새 찾기 산책", "낙엽, 군밤, 찬 바람.", .senses, [.sensory, .outdoors], 20, near(20), seasons: [.autumn]),

        e("making-print-photo", "사진 한 장 인화해서 세워 두기", "편의점 인화기도 있어요.", .making, [.making, .pretty], 30, near(20), 3_000),
        e("making-knit-start", "뜨개질로 코 잡기", "영상 하나 보고 스무 코만.", .making, [.making, .slow, .learning], 40, .home, 10_000),
        e("making-clay-dish", "지점토로 작은 그릇 만들기", "반지 하나 올려 둘 크기로.", .making, [.making, .sensory], 40, .home, 5_000),
        e("making-year-card", "손으로 연말 카드 만들기", "한 사람에게만.", .making, [.making, .together, .pretty], 40, .home, 3_000, seasons: [.winter]),
        e("making-pressed-petal", "꽃잎 눌러 말리기", "두꺼운 책 사이에 일주일.", .making, [.making, .pretty, .slow], 20, .home, seasons: [.spring, .summer]),

        e("conn-hello-neighbor", "이웃에게 먼저 인사하기", "엘리베이터에서 한마디.", .connection, [.together, .novel], 1, near(0)),
        e("conn-call-parent", "부모님이나 가족에게 전화 10분", "용건 없이.", .connection, [.together, .slow], 10, .home),
        e("conn-lend-book", "좋아하는 책 빌려주기", "왜 좋았는지 쪽지 하나 끼워서.", .connection, [.together, .refreshing], 10, .home),
        e("conn-summer-night", "여름밤 누군가와 산책", "편의점 아이스크림 하나씩.", .connection, [.together, .outdoors, .slow], 40, near(0), company: true, seasons: [.summer]),
        e("conn-new-year-wish", "새해 소원 서로 적어 보기", "접어서 일 년 뒤에 열어요.", .connection, [.together, .slow], 20, .home, company: true, seasons: [.winter]),
    ]
}

import Foundation

/// 숲에 공개되는 정보의 전부.
///
/// 무엇을 끊는지, 정확한 일수, 아낀 돈, 이유는 여기에 절대 넣지 않는다.
/// 꾸민 모습(잎 색, 장식)은 보인다. 하늘은 내 화면에만 있다.
/// 필드를 추가할 때는 PublicTreeTests의 허용 목록도 같이 바꿔야 한다.
public struct PublicTree: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var stage: GrowthStage
    public var isWilting: Bool
    public var urgingSince: Date?
    /// "같은 날 시작한 사람들"을 묶는 데만 쓴다.
    public var startDay: String
    public var updatedAt: Date
    /// 꾸민 잎 색. 꾸미기 전이거나 예전 앱이면 nil(초록 잎).
    public var leaf: GardenItem?
    public var decorations: [GardenItem]

    public init(
        id: String,
        name: String,
        stage: GrowthStage,
        isWilting: Bool,
        urgingSince: Date?,
        startDay: String,
        updatedAt: Date,
        leaf: GardenItem? = nil,
        decorations: [GardenItem] = []
    ) {
        self.id = id
        self.name = name
        self.stage = stage
        self.isWilting = isWilting
        self.urgingSince = urgingSince
        self.startDay = startDay
        self.updatedAt = updatedAt
        self.leaf = leaf
        self.decorations = decorations
    }

    public init(
        id: String,
        name: String,
        habit: Habit,
        style: GardenStyle? = nil,
        urgingSince: Date?,
        now: Date,
        calendar: Calendar = .current
    ) {
        self.init(
            id: id,
            name: name,
            stage: habit.stage(at: now),
            isWilting: habit.isWilting(at: now),
            urgingSince: urgingSince,
            startDay: DayKey.make(habit.startedAt, calendar: calendar),
            updatedAt: now,
            leaf: style?.leaf,
            decorations: style?.decorations ?? []
        )
    }

    /// 숲에서 이 나무를 그릴 모습. 다른 기기가 보낸 값이니 한 번 더 걸러 낸다.
    public var style: GardenStyle {
        GardenStyle(leaf: leaf ?? .leafSpring, sky: .skyDay, decorations: decorations)
    }

    public func isUrging(at now: Date) -> Bool {
        guard let since = urgingSince else { return false }
        let elapsed = now.timeIntervalSince(since)
        return elapsed >= 0 && elapsed < UrgeSession.publicWindow
    }

    /// 최근 일주일 안에 앱을 연 나무는 "아직 걷는 중".
    public func isActive(at now: Date) -> Bool {
        now.timeIntervalSince(updatedAt) < 7 * 86_400
    }
}

public struct Cohort: Equatable, Sendable {
    public var total: Int
    public var active: Int
}

public enum ForestStats {
    public static func urgingCount(_ trees: [PublicTree], now: Date) -> Int {
        trees.filter { $0.isUrging(at: now) }.count
    }

    public static func cohort(_ trees: [PublicTree], startDay: String, now: Date) -> Cohort {
        let same = trees.filter { $0.startDay == startDay }
        return Cohort(total: same.count, active: same.filter { $0.isActive(at: now) }.count)
    }

    /// 지금 참는 나무를 앞에, 나머지는 큰 나무부터.
    public static func sorted(_ trees: [PublicTree], now: Date) -> [PublicTree] {
        trees.sorted { a, b in
            let ua = a.isUrging(at: now), ub = b.isUrging(at: now)
            if ua != ub { return ua }
            if a.stage != b.stage { return a.stage > b.stage }
            return a.updatedAt > b.updatedAt
        }
    }
}

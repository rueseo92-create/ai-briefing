import Foundation

/// 계절 묶음. 겨울은 12월이 속한 해로 센다(2026년 12월 ~ 2027년 2월 = 2026 겨울).
public struct SeasonKey: Hashable, Comparable, Sendable {
    public var year: Int
    public var season: Season

    public init(year: Int, season: Season) {
        self.year = year
        self.season = season
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        self.init(year: month <= 2 ? year - 1 : year, season: Season(month: month))
    }

    public var title: String { "\(year) \(season.title)" }

    public static func < (lhs: SeasonKey, rhs: SeasonKey) -> Bool {
        (lhs.year, Season.allCases.firstIndex(of: lhs.season)!) < (rhs.year, Season.allCases.firstIndex(of: rhs.season)!)
    }
}

/// 실물 엽서 인쇄 묶음.
public enum PrintPack {
    public static let size = 8

    /// 엽서가 있는 계절들, 최근 것부터.
    public static func seasons(_ entries: [Entry], calendar: Calendar = .current) -> [(key: SeasonKey, count: Int)] {
        Dictionary(grouping: entries) { SeasonKey($0.at, calendar: calendar) }
            .map { (key: $0.key, count: $0.value.count) }
            .sorted { $0.key > $1.key }
    }

    /// 그 계절의 엽서 중 인쇄하기 좋은 것: 사진 있는 것, 좋았어요, 오래된 순서로 최대 8장.
    public static func suggest(_ entries: [Entry], for key: SeasonKey, calendar: Calendar = .current) -> [Entry] {
        let inSeason = entries.filter { SeasonKey($0.at, calendar: calendar) == key }
        let ranked = inSeason.sorted { a, b in
            let pa = (a.photo != nil ? 2 : 0) + (a.feeling == .liked ? 1 : 0)
            let pb = (b.photo != nil ? 2 : 0) + (b.feeling == .liked ? 1 : 0)
            return pa != pb ? pa > pb : a.at < b.at
        }
        return ranked.prefix(size).sorted { $0.at < $1.at }
    }
}

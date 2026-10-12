import Foundation

/// 한 주에 한 번 보내는 익명 숫자. 사용자가 켰을 때만 보낸다.
/// 누가 보냈는지, 무엇을 했는지, 어디서 했는지, 메모와 사진은 절대 넣지 않는다. 주마다 따로라 주끼리 이어 볼 수도 없다.
/// 필드를 추가할 때는 WeeklyReportTests의 허용 목록도 같이 바꿔야 한다.
public struct WeeklyReport: Codable, Equatable, Sendable {
    public var week: String
    public var checkedIn: Bool
    public var postcards: Int
    public var withPhoto: Int
    public var liked: Int
    public var swapsTooExpensive: Int
    public var swapsNoTime: Int
    public var swapsOther: Int
    public var adCodeCopies: Int

    public static func make(week: String, journal: Journal, checkedIn: Bool, calendar: Calendar = .current) -> WeeklyReport {
        let entries = journal.entries.filter { Week.key($0.at, calendar: calendar) == week }
        let swaps = journal.swaps.filter { Week.key($0.at, calendar: calendar) == week }
        return WeeklyReport(
            week: week,
            checkedIn: checkedIn,
            postcards: entries.count,
            withPhoto: entries.filter { $0.photo != nil }.count,
            liked: entries.filter { $0.feeling == .liked }.count,
            swapsTooExpensive: swaps.filter { $0.reason == .tooExpensive }.count,
            swapsNoTime: swaps.filter { $0.reason == .noTime }.count,
            swapsOther: swaps.filter { $0.reason != .tooExpensive && $0.reason != .noTime }.count,
            adCodeCopies: journal.codeCopies.filter { Week.key($0, calendar: calendar) == week }.count
        )
    }
}

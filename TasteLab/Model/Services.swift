import Foundation
import TasteCore

/// 바깥 세상과 닿는 것들. AppModel은 이 약속만 알고, 실제 구현(CloudKit, 알림, 날씨, 지도)은 앱 쪽에 있다.
/// 모두 없어도(nil) 앱은 기기 안에서만 그대로 돈다.

enum AppConfig {
    /// CloudKit 컨테이너를 만든 뒤 여기에 넣으면 iCloud 백업과 익명 주간 숫자가 켜진다. (README 참고)
    static let cloudKitContainer: String? = nil
    /// 의견 보내기를 받을 주소.
    static let feedbackEmail = "feedback@example.com"
}

/// 사용자 본인의 iCloud(비공개 데이터베이스)에 백업한다. 우리 서버로는 가지 않는다.
protocol BackupService: Sendable {
    func isAvailable() async -> Bool
    func upload(state: Data, photos: [String: URL]) async throws
    func downloadState() async throws -> Data?
    func downloadPhotos(_ names: [String], into store: PhotoStore) async throws
    func deleteAll(photoNames: [String]) async throws
}

/// 익명 주간 숫자를 보낸다.
protocol MetricsService: Sendable {
    func send(_ report: WeeklyReport) async throws
}

/// 기기 안에서만 울리는 알림.
protocol ReminderSink: Sendable {
    func requestPermission() async -> Bool
    func replace(with reminders: [Reminder]) async
    func cancelAll() async
}

protocol WeatherProvider: Sendable {
    func outlook(for origin: Coordinate) async -> WeatherOutlook?
}

protocol PlaceSearcher: Sendable {
    func search(around origin: Coordinate) async -> NearbyPlaces?
}

/// 실험을 하다 생긴 문제. 장소 문제면 그 장소를 다시 권하지 않는다.
enum ProblemReport: String, CaseIterable, Sendable {
    case closed
    case notThere
    case tooFar
    case costDifferent
    case other

    var title: String {
        switch self {
        case .closed: "문이 닫혀 있었어요"
        case .notThere: "그런 곳이 없었어요"
        case .tooFar: "생각보다 멀었어요"
        case .costDifferent: "비용이 달랐어요"
        case .other: "다른 문제가 있었어요"
        }
    }

    /// 이 장소를 다시 권하지 않을지.
    var blocksVenue: Bool { self == .closed || self == .notThere }
}

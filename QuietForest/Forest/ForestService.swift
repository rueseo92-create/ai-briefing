import Foundation
import ForestCore

/// 숲(다른 사람들의 나무)과 주고받는 것의 전부: 내 나무 모습, 물방울.
protocol ForestService: Sendable {
    func publish(_ tree: PublicTree) async throws
    func remove(treeID: String) async throws
    func fetchForest() async throws -> [PublicTree]
    func fetchCohort(startDay: String) async throws -> [PublicTree]
    func sendCheer(to treeID: String) async throws
    /// since 이후에 내 나무가 받은 물방울 수.
    func fetchCheers(for treeID: String, since: Date) async throws -> Int
}

enum AppConfig {
    /// CloudKit 컨테이너를 만든 뒤 여기에 넣으면 진짜 숲에 연결된다. (README 참고)
    /// nil이면 기기 안에서만 도는 가짜 숲으로 동작한다.
    static let cloudKitContainer: String? = nil

    static func makeService() -> ForestService {
        if let container = cloudKitContainer {
            return CloudKitForestService(containerID: container)
        }
        return MockForestService()
    }
}

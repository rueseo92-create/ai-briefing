import Foundation
import ForestCore

/// 서버 없이 숲을 흉내 낸다. 시뮬레이터에서 화면을 확인하는 용도.
actor MockForestService: ForestService {
    private var trees: [String: PublicTree] = [:]
    private var myTree: PublicTree?
    private var pendingCheers = 0

    init() {
        let now = Date()
        let today = DayKey.make(now)
        var generated: [String: PublicTree] = [:]
        for index in 0..<36 {
            let id = UUID()
            let stage = GrowthStage.allCases.randomElement() ?? .seed
            let tree = PublicTree(
                id: id.uuidString,
                name: TreeName.make(seed: id),
                stage: stage,
                isWilting: Int.random(in: 0..<10) == 0,
                urgingSince: Int.random(in: 0..<6) == 0 ? now : nil,
                startDay: index < 9 ? today : DayKey.make(now.addingTimeInterval(-Double(index) * 86_400)),
                updatedAt: now.addingTimeInterval(-Double.random(in: 0...(10 * 86_400)))
            )
            generated[tree.id] = tree
        }
        trees = generated
    }

    func publish(_ tree: PublicTree) async throws {
        myTree = tree
    }

    func remove(treeID: String) async throws {
        myTree = nil
    }

    func fetchForest() async throws -> [PublicTree] {
        let now = Date()
        // 몇 그루는 지금 막 참기 시작하고, 몇 그루는 참기를 끝낸다.
        for id in trees.keys.shuffled().prefix(3) {
            trees[id]?.urgingSince = Bool.random() ? now : nil
            trees[id]?.updatedAt = now
        }
        return trees.values.filter { $0.isActive(at: now) }
    }

    func fetchCohort(startDay: String) async throws -> [PublicTree] {
        (Array(trees.values) + [myTree].compactMap { $0 }).filter { $0.startDay == startDay }
    }

    func sendCheer(to treeID: String) async throws {}

    func fetchCheers(for treeID: String, since: Date) async throws -> [IncomingCheer] {
        // 내가 참는 중이면 가끔 누군가 물을 준다.
        if let mine = myTree, mine.isUrging(at: Date()), Int.random(in: 0..<3) == 0 {
            pendingCheers += 1
        }
        defer { pendingCheers = 0 }
        return (0..<pendingCheers).map { _ in IncomingCheer(sender: UUID().uuidString, sentAt: Date()) }
    }
}

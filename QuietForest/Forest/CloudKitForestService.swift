import CloudKit
import ForestCore

/// CloudKit 공개 데이터베이스로 만든 숲. 서버를 따로 두지 않는다.
///
/// 레코드 타입 (CloudKit Console에서 인덱스를 만들어야 한다. README 참고)
/// - Tree:  name, stage, isWilting, urgingSince, startDay, updatedAt   (recordName = 나무 id)
/// - Cheer: target, sentAt
final class CloudKitForestService: ForestService, @unchecked Sendable {
    private let database: CKDatabase

    /// 참는 중이 아닐 때 urgingSince에 넣는 값. nil을 저장하면 덮어쓰기가 안 되는 경우가 있어서 쓴다.
    private static let notUrging = Date(timeIntervalSince1970: 0)

    init(containerID: String) {
        database = CKContainer(identifier: containerID).publicCloudDatabase
    }

    func publish(_ tree: PublicTree) async throws {
        let record = CKRecord(recordType: "Tree", recordID: CKRecord.ID(recordName: tree.id))
        record["name"] = tree.name
        record["stage"] = tree.stage.rawValue
        record["isWilting"] = tree.isWilting ? 1 : 0
        record["urgingSince"] = tree.urgingSince ?? Self.notUrging
        record["startDay"] = tree.startDay
        record["updatedAt"] = tree.updatedAt
        _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
    }

    func remove(treeID: String) async throws {
        _ = try await database.deleteRecord(withID: CKRecord.ID(recordName: treeID))
    }

    func fetchForest() async throws -> [PublicTree] {
        let since = Date().addingTimeInterval(-7 * 86_400)
        let query = CKQuery(recordType: "Tree", predicate: NSPredicate(format: "updatedAt > %@", since as NSDate))
        query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return try await trees(matching: query, limit: 200)
    }

    func fetchCohort(startDay: String) async throws -> [PublicTree] {
        let query = CKQuery(recordType: "Tree", predicate: NSPredicate(format: "startDay == %@", startDay))
        return try await trees(matching: query, limit: 400)
    }

    func sendCheer(to treeID: String) async throws {
        let record = CKRecord(recordType: "Cheer")
        record["target"] = treeID
        record["sentAt"] = Date()
        _ = try await database.save(record)
    }

    /// 보낸 사람은 CloudKit이 붙이는 앱 전용 사용자 id로만 구분한다. 중복을 세지 않는 데만 쓰고 화면에는 보이지 않는다.
    func fetchCheers(for treeID: String, since: Date) async throws -> [IncomingCheer] {
        let predicate = NSPredicate(format: "target == %@ AND sentAt > %@", treeID, since as NSDate)
        let (results, _) = try await database.records(
            matching: CKQuery(recordType: "Cheer", predicate: predicate),
            desiredKeys: ["sentAt"],
            resultsLimit: 100
        )
        return results.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return IncomingCheer(
                sender: record.creatorUserRecordID?.recordName,
                sentAt: record["sentAt"] as? Date ?? since
            )
        }
    }

    private func trees(matching query: CKQuery, limit: Int) async throws -> [PublicTree] {
        let (results, _) = try await database.records(matching: query, resultsLimit: limit)
        return results.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return Self.tree(from: record)
        }
    }

    private static func tree(from record: CKRecord) -> PublicTree? {
        guard
            let name = record["name"] as? String,
            let stageValue = record["stage"] as? Int,
            let stage = GrowthStage(rawValue: stageValue),
            let startDay = record["startDay"] as? String,
            let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        let urging = record["urgingSince"] as? Date
        return PublicTree(
            id: record.recordID.recordName,
            name: name,
            stage: stage,
            isWilting: (record["isWilting"] as? Int ?? 0) == 1,
            urgingSince: urging == notUrging ? nil : urging,
            startDay: startDay,
            updatedAt: updatedAt
        )
    }
}

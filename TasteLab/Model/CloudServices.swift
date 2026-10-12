import CloudKit
import TasteCore

/// 사용자 본인 iCloud의 비공개 데이터베이스에 백업한다. 개발자도 볼 수 없다.
/// 레코드: State(recordName "state", file: 상태 JSON), Photo(recordName = 사진 파일 이름, image)
final class CloudKitBackup: BackupService, @unchecked Sendable {
    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }
    private static let stateID = CKRecord.ID(recordName: "state")
    private static let chunk = 50

    init(containerID: String) {
        container = CKContainer(identifier: containerID)
    }

    func isAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    func upload(state: Data, photos: [String: URL]) async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("state-\(UUID().uuidString).json")
        try state.write(to: temp)
        defer { try? FileManager.default.removeItem(at: temp) }

        let stateRecord = CKRecord(recordType: "State", recordID: Self.stateID)
        stateRecord["file"] = CKAsset(fileURL: temp)
        stateRecord["updatedAt"] = Date()
        var records = [stateRecord]
        for (name, url) in photos {
            let record = CKRecord(recordType: "Photo", recordID: CKRecord.ID(recordName: name))
            record["image"] = CKAsset(fileURL: url)
            records.append(record)
        }
        for start in stride(from: 0, to: records.count, by: Self.chunk) {
            let part = Array(records[start..<min(start + Self.chunk, records.count)])
            let (results, _) = try await database.modifyRecords(saving: part, deleting: [], savePolicy: .allKeys)
            for (_, result) in results { _ = try result.get() }
        }
    }

    func downloadState() async throws -> Data? {
        do {
            let record = try await database.record(for: Self.stateID)
            guard let url = (record["file"] as? CKAsset)?.fileURL else { return nil }
            return try Data(contentsOf: url)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func downloadPhotos(_ names: [String], into store: PhotoStore) async throws {
        try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        for start in stride(from: 0, to: names.count, by: Self.chunk) {
            let ids = names[start..<min(start + Self.chunk, names.count)].map { CKRecord.ID(recordName: $0) }
            let results = try await database.records(for: ids)
            for (id, result) in results {
                guard let record = try? result.get(), let url = (record["image"] as? CKAsset)?.fileURL else { continue }
                let target = store.url(for: id.recordName)
                try? FileManager.default.removeItem(at: target)
                try FileManager.default.copyItem(at: url, to: target)
            }
        }
    }

    func deleteAll(photoNames: [String]) async throws {
        let ids = [Self.stateID] + photoNames.map { CKRecord.ID(recordName: $0) }
        for start in stride(from: 0, to: ids.count, by: Self.chunk) {
            _ = try await database.modifyRecords(saving: [], deleting: Array(ids[start..<min(start + Self.chunk, ids.count)]))
        }
    }
}

/// 익명 주간 숫자를 CloudKit 공개 데이터베이스에 남긴다. 누가 보냈는지 알 수 있는 값은 없다.
/// 레코드: WeeklyReport(week, checkedIn, postcards, withPhoto, liked, swapsTooExpensive, swapsNoTime, swapsOther, adCodeCopies)
final class CloudKitMetrics: MetricsService, @unchecked Sendable {
    private let database: CKDatabase

    init(containerID: String) {
        database = CKContainer(identifier: containerID).publicCloudDatabase
    }

    func send(_ report: WeeklyReport) async throws {
        let record = CKRecord(recordType: "WeeklyReport")
        record["week"] = report.week
        record["checkedIn"] = report.checkedIn ? 1 : 0
        record["postcards"] = report.postcards
        record["withPhoto"] = report.withPhoto
        record["liked"] = report.liked
        record["swapsTooExpensive"] = report.swapsTooExpensive
        record["swapsNoTime"] = report.swapsNoTime
        record["swapsOther"] = report.swapsOther
        record["adCodeCopies"] = report.adCodeCopies
        _ = try await database.save(record)
    }
}

/// 제휴처 제안을 CloudKit 공개 데이터베이스에서 받는다. 운영자가 offer-check로 검사한 파일을 OfferFile 레코드(file 자산)로 올려 둔다.
/// 앱은 전부 받아서 한 번 더 검사하고, 무엇을 보여 줄지는 기기 안에서 고른다.
final class CloudKitOfferService: OfferService, @unchecked Sendable {
    private let database: CKDatabase

    init(containerID: String) {
        database = CKContainer(identifier: containerID).publicCloudDatabase
    }

    func fetchOffers() async throws -> [Experiment] {
        let query = CKQuery(recordType: "OfferFile", predicate: NSPredicate(value: true))
        let (results, _) = try await database.records(matching: query, desiredKeys: ["file"], resultsLimit: 200)
        var experiments: [Experiment] = []
        for (_, result) in results {
            guard let record = try? result.get(),
                  let url = (record["file"] as? CKAsset)?.fileURL,
                  let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(OfferFile.self, from: data) else { continue }
            experiments += OfferValidator.experiments(from: file, now: Date())
        }
        return experiments
    }
}

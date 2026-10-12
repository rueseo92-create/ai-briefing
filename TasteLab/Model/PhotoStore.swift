import Foundation

/// 엽서 사진을 두는 곳. 이 기기의 앱 폴더 안에만 저장하고 서버로 보내지 않는다.
struct PhotoStore: Sendable {
    let directory: URL

    static var standard: PhotoStore {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("postcards", isDirectory: true)
        return PhotoStore(directory: folder)
    }

    func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    /// 이미 JPEG로 만든 데이터를 저장하고 파일 이름을 돌려준다.
    func save(jpeg data: Data) -> String? {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: url(for: name), options: [.atomic, .completeFileProtection])
            return name
        } catch {
            return nil
        }
    }

    func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}

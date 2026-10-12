import Foundation

/// 친구에게 "같이 해 볼래?" 링크. 실험 id와 (원하면) 보낸 사람 이름만 담는다. 서버를 거치지 않는다.
public struct Invite: Equatable, Sendable {
    public static let scheme = "tastepostcard"
    public static let maxNameLength = 12

    public var experimentID: String
    public var from: String?

    public init(experimentID: String, from: String?) {
        self.experimentID = experimentID
        // 자른 뒤에도 끝 공백을 다시 지운다. 그래야 링크를 주고받아도 이름이 같다.
        let name = String((from ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.from = name.isEmpty ? nil : name
    }

    /// tastepostcard://invite?e=breath-poem&from=지수
    public var url: URL {
        var parts = URLComponents()
        parts.scheme = Self.scheme
        parts.host = "invite"
        parts.queryItems = [URLQueryItem(name: "e", value: experimentID)] + (from.map { [URLQueryItem(name: "from", value: $0)] } ?? [])
        return parts.url!
    }

    public init?(url: URL) {
        guard url.scheme == Self.scheme, url.host == "invite",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let id = items.first(where: { $0.name == "e" })?.value,
              !id.isEmpty, id.count <= 64,
              id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") })
        else { return nil }
        self.init(experimentID: id, from: items.first { $0.name == "from" }?.value)
    }

    public func experiment(in catalog: [Experiment]) -> Experiment? {
        catalog.first { $0.id == experimentID }
    }

    public var senderName: String { from ?? "친구" }

    /// 메시지 앱으로 보낼 글.
    public func message(for experiment: Experiment) -> String {
        "같이 해 볼래? ‘\(experiment.title)’ — 취향 엽서에서 열기: \(url.absoluteString)"
    }
}

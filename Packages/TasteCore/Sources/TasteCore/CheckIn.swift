import Foundation

/// 매주 실험을 받기 전에 묻는 네 가지. 앱이 정하지 않고 사용자가 고른다. 답은 기기에만 남는다.
public struct CheckIn: Codable, Equatable, Sendable {
    public enum Budget: Int, Codable, CaseIterable, Sendable {
        case free
        case under10k
        case under30k
        case any

        /// 쓸 수 있는 최대 금액(원). nil이면 상관없음.
        public var limit: Int? {
            switch self {
            case .free: 0
            case .under10k: 10_000
            case .under30k: 30_000
            case .any: nil
            }
        }

        public var title: String {
            switch self {
            case .free: "0원"
            case .under10k: "1만 원까지"
            case .under30k: "3만 원까지"
            case .any: "그 이상도 괜찮아요"
            }
        }

        /// 한 칸 낮춘 예산. "돈이 들어서" 바꿀 때.
        public var lowered: Budget {
            Budget(rawValue: rawValue - 1) ?? .free
        }
    }

    public enum Energy: Int, Codable, CaseIterable, Sendable {
        case low
        case normal
        case high

        public var title: String {
            switch self {
            case .low: "낮음"
            case .normal: "보통"
            case .high: "높음"
            }
        }
    }

    public enum TimeBudget: Int, Codable, CaseIterable, Sendable {
        case short
        case halfDay
        case fullDay

        /// 실험 시간 + 오가는 시간의 최대(분).
        public var totalLimit: Int {
            switch self {
            case .short: 30
            case .halfDay: 240
            case .fullDay: 600
            }
        }

        /// 오가는 시간(왕복)의 최대(분).
        public var travelLimit: Int {
            switch self {
            case .short: 20
            case .halfDay: 60
            case .fullDay: 180
            }
        }

        public var title: String {
            switch self {
            case .short: "짧게 (30분 이내)"
            case .halfDay: "반나절"
            case .fullDay: "하루 통째로"
            }
        }
    }

    public enum Company: Int, Codable, CaseIterable, Sendable {
        case solo
        case together

        public var title: String {
            switch self {
            case .solo: "혼자"
            case .together: "누군가와 함께"
            }
        }
    }

    public var budget: Budget
    public var energy: Energy
    public var time: TimeBudget
    public var company: Company

    public init(budget: Budget, energy: Energy, time: TimeBudget, company: Company) {
        self.budget = budget
        self.energy = energy
        self.time = time
        self.company = company
    }

    public static let standard = CheckIn(budget: .under10k, energy: .normal, time: .halfDay, company: .solo)

    /// 에너지가 낮은 주에 나오는 실험의 최대 길이(분).
    public static let lowEnergyMinutes = 20

    /// 이번 주 답으로 이 실험을 할 수 있는지. travelMinutes가 nil이면 갈 수 없는 곳이다(위치가 없음).
    public func allows(_ experiment: Experiment, travelMinutes: Int?) -> Bool {
        if let limit = budget.limit, experiment.effectiveCost > limit { return false }
        if energy == .low, experiment.minutes > Self.lowEnergyMinutes || experiment.tags.contains(.moving) { return false }
        guard let travel = travelMinutes else { return false }
        if travel > time.travelLimit || experiment.minutes + travel > time.totalLimit { return false }
        if company == .solo, experiment.needsCompany { return false }
        return true
    }
}

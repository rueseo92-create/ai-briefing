import Foundation
import TasteCore

/// 광고 실험과 주말 키트를 받아 오는 곳.
///
/// 광고주는 사용자의 기록을 받지 않는다. 앱은 모든 제안을 통째로 받아 와서,
/// 누구에게 무엇을 보여 줄지는 이 기기 안의 Recommender가 정한다.
protocol OfferService: Sendable {
    func fetchOffers() async throws -> [Experiment]
}

/// 서버 없이 예시 제안으로 동작한다. 실제 서비스는 CloudKit 공개 DB(읽기 전용)로 바꾼다. README 참고.
struct SampleOfferService: OfferService {
    func fetchOffers() async throws -> [Experiment] {
        SampleOffers.all
    }
}

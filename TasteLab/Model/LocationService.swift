import CoreLocation
import TasteCore

/// 대략적 위치(수 km)만 받는다. Info.plist의 NSLocationDefaultAccuracyReduced로 정확한 위치는 아예 요청하지 않는다.
/// 받은 위치는 기기 안에서 거리 계산에만 쓴다.
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var waiting: CheckedContinuation<Coordinate?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    /// 거절했거나 받지 못하면 nil.
    func requestApproximate() async -> Coordinate? {
        if waiting != nil { return nil }
        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        default:
            break
        }
        return await withCheckedContinuation { continuation in
            waiting = continuation
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    private func finish(_ coordinate: Coordinate?) {
        waiting?.resume(returning: coordinate)
        waiting = nil
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last.map { Coordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
        Task { @MainActor in self.finish(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard self.waiting != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                self.finish(nil)
            default:
                break
            }
        }
    }
}

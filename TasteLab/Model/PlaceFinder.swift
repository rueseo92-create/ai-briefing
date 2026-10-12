import MapKit
import TasteCore

/// Apple 지도에서 동네 근처의 실제 장소를 찾는다.
/// 검색어와 동네 범위는 Apple 지도로 가지만, 우리 서버로는 아무것도 가지 않는다. 결과는 이 기기에만 저장한다.
enum PlaceFinder {
    /// 찾지 못했으면(네트워크 끊김 등) nil. 이때는 예전 결과를 그대로 둔다.
    @MainActor
    static func search(around origin: Coordinate, needs: [PlaceNeed] = PlaceNeed.allCases) async -> NearbyPlaces? {
        var found: [PlaceNeed: [Venue]] = [:]
        var answered = 0
        for need in needs {
            var venues: [Venue] = []
            for query in need.queries {
                guard let result = await search(query, around: origin, radiusKm: need.radiusKm) else { continue }
                answered += 1
                venues += result
                if venues.count >= NearbyPlaces.maxPerNeed { break }
            }
            found[need] = venues
        }
        guard answered > 0 else { return nil }
        return NearbyPlaces(origin: origin, foundAt: Date(), places: found)
    }

    /// 검색이 실패하면 nil, 결과가 없으면 빈 배열.
    private static func search(_ query: String, around origin: Coordinate, radiusKm: Double) async -> [Venue]? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude),
            latitudinalMeters: radiusKm * 2_000,
            longitudinalMeters: radiusKm * 2_000
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.map { item in
                let point = item.placemark.coordinate
                return Venue(
                    name: item.name ?? query,
                    coordinate: Coordinate(latitude: point.latitude, longitude: point.longitude),
                    address: item.placemark.title
                )
            }
        } catch let error as MKError where error.code == .placemarkNotFound {
            return []
        } catch {
            return nil
        }
    }
}

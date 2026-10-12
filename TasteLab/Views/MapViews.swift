import SwiftUI
import MapKit
import TasteCore

extension PlaceNeed {
    var symbol: String {
        switch self {
        case .park: "tree"
        case .waterside: "water.waves"
        case .trail: "figure.hiking"
        case .barefootPath: "shoeprints.fill"
        case .arboretum: "leaf"
        case .library: "books.vertical"
        case .bookstore: "book"
        case .gallery: "photo.artframe"
        case .market: "basket"
        case .grocery: "cart"
        case .bakery: "birthday.cake"
        case .flowerShop: "camera.macro"
        case .scentShop: "drop"
        case .sauna: "humidity"
        case .quietYard: "building.columns"
        case .fitness: "figure.climbing"
        case .craftStudio: "paintbrush"
        case .liveVenue: "music.mic"
        case .boardGameCafe: "dice"
        case .campfire: "flame"
        case .postOffice: "envelope"
        }
    }
}

extension Coordinate {
    var clLocation: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

enum MapLinks {
    /// Apple 지도 앱에서 그 장소 열기.
    static func appleMaps(_ venue: Venue) -> URL? {
        var parts = URLComponents(string: "https://maps.apple.com/")
        parts?.queryItems = [
            URLQueryItem(name: "q", value: venue.name),
            URLQueryItem(name: "ll", value: "\(venue.coordinate.latitude),\(venue.coordinate.longitude)"),
        ]
        return parts?.url
    }
}

/// 실험 상세에 붙는 작은 지도. 실제로 갈 곳과 오가는 시간.
struct VenueMapCard: View {
    let venue: Venue
    let origin: Coordinate?
    let travel: Int?
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Map(initialPosition: .region(region)) {
                Marker(venue.name, coordinate: venue.coordinate.clLocation)
                if let origin {
                    Annotation("출발", coordinate: origin.clLocation) {
                        Image(systemName: "house.fill")
                            .padding(6)
                            .background(.white, in: Circle())
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .allowsHitTesting(false)

            Text(venue.name).font(.headline)
            if let address = venue.address { Text(address).font(.footnote).foregroundStyle(Theme.muted) }
            if let travel { Text("오가는 시간 약 \(Formats.minutes(travel)) (직선 거리로 잰 대략의 값)").font(.footnote).foregroundStyle(Theme.muted) }
            Label("가기 전에 지도 앱에서 영업시간을 확인해 주세요.", systemImage: "clock.badge.questionmark")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            if let url = MapLinks.appleMaps(venue) {
                Button("지도 앱에서 열기") { openURL(url) }
                    .buttonStyle(.bordered)
            }
        }
        .card()
    }

    private var region: MKCoordinateRegion {
        guard let origin else {
            return MKCoordinateRegion(center: venue.coordinate.clLocation, latitudinalMeters: 1_500, longitudinalMeters: 1_500)
        }
        let center = CLLocationCoordinate2D(latitude: (origin.latitude + venue.coordinate.latitude) / 2, longitude: (origin.longitude + venue.coordinate.longitude) / 2)
        let span = max(origin.distanceKm(to: venue.coordinate) * 1_000 * 1.6, 1_500)
        return MKCoordinateRegion(center: center, latitudinalMeters: span, longitudinalMeters: span)
    }
}

/// 동네 지도. 지도에서 찾은 실제 장소와, 근처에 없어서 나오지 않는 실험 종류.
struct NeighborhoodMapView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var searching = false
    @State private var focus: PlaceNeed?

    private struct Pin: Identifiable {
        let id: String
        let need: PlaceNeed
        let venue: Venue
    }

    var body: some View {
        let origin = model.location.origin
        let nearby = model.nearby
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let origin {
                    Map(initialPosition: .region(MKCoordinateRegion(center: origin.clLocation, latitudinalMeters: 9_000, longitudinalMeters: 9_000))) {
                        Annotation("출발", coordinate: origin.clLocation) {
                            Image(systemName: "house.fill").padding(6).background(.white, in: Circle()).foregroundStyle(Theme.accent)
                        }
                        ForEach(pins(nearby)) { pin in
                            Marker(pin.venue.name, systemImage: pin.need.symbol, coordinate: pin.venue.coordinate.clLocation)
                                .tint(focus == nil || focus == pin.need ? Theme.accent : .gray)
                        }
                    }
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if let nearby {
                        Text("\(nearby.foundAt.formatted(.dateTime.month().day().locale(Locale(identifier: "ko_KR"))))에 Apple 지도에서 찾았어요. 근처에 실제로 있는 곳이 필요한 실험만 이걸로 골라요.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                        needList(nearby)
                    } else {
                        Text("아직 동네 지도를 확인하지 않았어요. 장소가 필요한 실험(한강, 숲길, 도서관 등)은 확인한 뒤에 나와요.")
                            .foregroundStyle(Theme.muted)
                            .card()
                    }

                    Button {
                        Task {
                            searching = true
                            if let places = await PlaceFinder.search(around: origin) { model.updateNearby(places) }
                            searching = false
                        }
                    } label: {
                        Label(searching ? "찾는 중…" : "지금 다시 찾기", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searching)

                    Text("검색어와 동네 범위는 Apple 지도로 가지만, 우리 서버로는 위치가 가지 않아요.")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                } else {
                    Text("위치 없이 쓰고 있어서 집과 동네 어디서나 할 수 있는 실험만 나와요. 설정에서 동네를 고르면 근처의 한강, 숲길, 도서관 같은 곳을 지도에서 찾아요.")
                        .card()
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationTitle("동네 지도")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
        }
    }

    private func pins(_ nearby: NearbyPlaces?) -> [Pin] {
        guard let nearby else { return [] }
        return PlaceNeed.allCases.flatMap { need in
            nearby.venues(for: need).map { Pin(id: need.rawValue + $0.name + "\($0.coordinate.latitude)", need: need, venue: $0) }
        }
    }

    private func needList(_ nearby: NearbyPlaces) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PlaceNeed.allCases) { need in
                let venues = nearby.venues(for: need)
                Button {
                    focus = focus == need ? nil : need
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: need.symbol).frame(width: 24).foregroundStyle(venues.isEmpty ? Theme.muted : Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(need.title).font(.callout.weight(.semibold))
                            if let first = venues.first, let origin = model.location.origin {
                                Text("\(first.name) · 오가는 시간 약 \(Formats.minutes(Travel.roundTripMinutes(from: origin, to: first.coordinate, mode: model.location.mode)))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                            } else {
                                Text("근처에서 못 찾았어요 · 이런 실험은 나오지 않아요").font(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                        Spacer()
                        Text(venues.isEmpty ? "없음" : "\(venues.count)곳").font(.caption.monospacedDigit()).foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(venues.isEmpty ? 0.6 : 1)
                Divider()
            }
        }
        .card()
    }
}

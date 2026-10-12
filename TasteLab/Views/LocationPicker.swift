import SwiftUI
import TasteCore

/// 위치를 어떻게 쓸지 고른다. 어느 쪽이든 위치는 서버로 보내지 않는다.
struct LocationPicker: View {
    @Binding var setting: LocationSetting

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(LocationSetting.Kind.allCases, id: \.self) { kind in
                Button {
                    setting.kind = kind
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: setting.kind == kind ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title(kind)).font(.headline)
                            Text(detail(kind)).font(.footnote).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if setting.kind != .none {
                Picker(setting.kind == .approximate ? "위치를 못 받을 때 쓸 동네" : "내 동네", selection: $setting.region) {
                    Text("고르기").tag(Region?.none)
                    ForEach(Regions.all) { region in
                        Text(region.name).tag(Region?.some(region))
                    }
                }
                .pickerStyle(.navigationLink)

                VStack(alignment: .leading, spacing: 8) {
                    Text("주로 어떻게 다녀요?").font(.subheadline.weight(.semibold))
                    FlowChips(options: TravelMode.allCases, selection: $setting.mode, title: \.title)
                }
            }
        }
    }

    private func title(_ kind: LocationSetting.Kind) -> String {
        switch kind {
        case .neighborhood: "동네만 고르기"
        case .approximate: "대략적 위치 쓰기"
        case .none: "위치 없이"
        }
    }

    private func detail(_ kind: LocationSetting.Kind) -> String {
        switch kind {
        case .neighborhood: "구나 도시를 직접 골라요. 위치 권한이 필요 없어요."
        case .approximate: "실험을 받을 때만 수 km 단위의 대략적 위치를 써요. 회사에서 받으면 회사 근처 실험이 나와요."
        case .none: "집과 동네 실험만 받아요. 공방·스튜디오 같은 특정 장소 실험은 나오지 않아요."
        }
    }
}

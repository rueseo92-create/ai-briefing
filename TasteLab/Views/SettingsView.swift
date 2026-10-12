import SwiftUI
import TasteCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LocationPicker(setting: Binding(
                        get: { model.location },
                        set: { model.setLocation($0) }
                    ))
                } header: {
                    Text("위치와 오가는 시간")
                } footer: {
                    Text("위치는 서버로 보내지 않아요. 장소 목록을 통째로 받아 이 폰 안에서 거리를 재요. 오가는 시간은 직선 거리에 보정값을 곱한 대략적인 값이에요.")
                }

                Section {
                    Toggle("광고 실험도 받기", isOn: Binding(
                        get: { model.allowSponsored },
                        set: { model.setAllowSponsored($0) }
                    ))
                } header: {
                    Text("광고")
                } footer: {
                    Text("광고 실험은 '광고'라고 표시되고, 한 번에 많아야 한 장이에요. 이번 주 예산과 시간 안에서만 보이고, '결이 같은' 자리에는 오지 않아요. 광고주는 내 기록, 예산, 위치를 받지 않아요.")
                }

                Section {
                    LabeledContent("모은 엽서", value: "\(model.journal.entries.count)장")
                    Button("엽서와 기록 모두 지우기", role: .destructive) { confirmReset = true }
                } header: {
                    Text("내 기록")
                } footer: {
                    Text("엽서, 사진, 기록은 이 폰에만 저장돼요.")
                }

                Section {
                    Text("힘들 때는 혼자 버티지 말고 도움을 받아요. 자살예방 상담전화 109 (24시간)")
                        .font(.footnote)
                } header: {
                    Text("도움이 필요할 때")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
            .confirmationDialog("엽서와 기록을 모두 지울까요?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("지우기", role: .destructive) {
                    model.resetEverything()
                    dismiss()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("사진도 함께 지워져요. 되돌릴 수 없어요.")
            }
        }
    }
}

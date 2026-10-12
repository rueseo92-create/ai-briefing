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
                    Toggle("광고 실험도 받기", isOn: Binding(
                        get: { model.allowSponsored },
                        set: { model.setAllowSponsored($0) }
                    ))
                } header: {
                    Text("광고")
                } footer: {
                    Text("광고 실험은 '광고'라고 표시되고, 한 번에 많아야 한 장이에요. '결이 같은' 자리에는 오지 않고, 별로였던 이유가 있는 광고는 나오지 않아요. 무엇을 보여 줄지는 이 폰 안에서 고르고, 광고주는 내 기록을 받지 않아요.")
                }

                Section {
                    LabeledContent("해 본 실험", value: "\(model.journal.entries.count)개")
                    Button("기록 모두 지우기", role: .destructive) { confirmReset = true }
                } header: {
                    Text("내 기록")
                } footer: {
                    Text("기록은 이 폰에만 저장돼요.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
            .confirmationDialog("모든 기록을 지울까요?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("지우기", role: .destructive) {
                    model.resetEverything()
                    dismiss()
                }
                Button("취소", role: .cancel) {}
            }
        }
    }
}

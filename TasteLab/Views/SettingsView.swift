import SwiftUI
import TasteCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var confirmReset = false
    @State private var restoring = false
    @State private var restoreFailed = false

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
                    Text("위치는 우리 서버로 보내지 않아요. 한강, 숲길, 도서관처럼 실제로 있어야 하는 곳은 Apple 지도에서 동네 근처를 찾아보고, 있을 때만 그 실험을 권해요. 오가는 시간은 직선 거리에 보정값을 곱한 대략적인 값이에요.")
                }

                Section {
                    NavigationLink("동네 지도 보기") { NeighborhoodMapView() }
                }

                Section {
                    TextField("예: 지수", text: Binding(get: { model.nickname }, set: { model.setNickname($0) }))
                } header: {
                    Text("친구에게 보일 이름 (선택)")
                } footer: {
                    Text("같이 하자고 보내는 링크에만 담겨요. 비워 두면 '친구'로 보여요.")
                }

                Section {
                    Toggle("알림 받기", isOn: Binding(
                        get: { model.remindersOn },
                        set: { on in Task { await model.setReminders(on) } }
                    ))
                } header: {
                    Text("알림")
                } footer: {
                    Text("월요일 아침 9시 체크인, 키트 주문 마감 날 아침, 토요일 아침 주말 계획. 이 폰에서만 울려요.")
                }

                Section {
                    Toggle("iCloud에 백업", isOn: Binding(
                        get: { model.backupOn },
                        set: { model.setBackup($0) }
                    ))
                    .disabled(!model.backupAvailable)
                    if model.backupOn {
                        LabeledContent("마지막 백업", value: model.lastBackupAt.map { $0.formatted(.relative(presentation: .named).locale(Locale(identifier: "ko_KR"))) } ?? "아직")
                        Button(model.isBackingUp ? "백업하는 중…" : "지금 백업") { Task { await model.backupNow() } }
                            .disabled(model.isBackingUp)
                    }
                    if model.backupAvailable, model.journal.entries.isEmpty {
                        Button(restoring ? "가져오는 중…" : "iCloud에서 엽서 가져오기") {
                            Task {
                                restoring = true
                                restoreFailed = !(await model.restoreFromBackup())
                                restoring = false
                            }
                        }
                        .disabled(restoring)
                    }
                } header: {
                    Text("백업")
                } footer: {
                    Text(model.backupAvailable
                         ? "엽서, 사진, 기록을 내 iCloud의 비공개 공간에 백업해요. 우리도 볼 수 없어요. 폰을 바꿔도 이어서 쓸 수 있어요."
                         : "iCloud에 로그인되어 있지 않거나 아직 iCloud 백업을 쓸 수 없는 버전이에요.")
                }

                Section {
                    Toggle("익명 주간 숫자 보내기", isOn: Binding(
                        get: { model.analyticsOn },
                        set: { model.setAnalytics($0) }
                    ))
                    .disabled(!model.canSendAnalytics)
                } header: {
                    Text("앱 개선에 보태기")
                } footer: {
                    Text("일주일에 한 번, 체크인했는지와 엽서 수·사진 넣은 수·좋았어요 수·바꾼 이유별 횟수·혜택 코드 복사 수만 보내요. 누가 보냈는지, 무엇을 했는지, 어디서 했는지, 메모와 사진은 보내지 않아요.")
                }

                Section {
                    Button("의견 보내기") {
                        if let url = URL(string: "mailto:\(AppConfig.feedbackEmail)?subject=%5B%EC%B7%A8%ED%96%A5%20%EC%97%BD%EC%84%9C%5D%20%EC%9D%98%EA%B2%AC") { openURL(url) }
                    }
                } footer: {
                    Text("실험 화면의 '문제가 있었나요?'로 장소 문제를 알려 주면 그곳은 다시 권하지 않아요.")
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
                Text("사진도 함께 지워져요. iCloud 백업도 지워요. 되돌릴 수 없어요.")
            }
            .alert("iCloud에서 가져올 엽서가 없어요", isPresented: $restoreFailed) {
                Button("확인", role: .cancel) {}
            }
        }
    }
}

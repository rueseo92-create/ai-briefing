import SwiftUI
import TasteCore

/// 처음 한 번. 앱이 무엇인지, 위치와 광고를 어떻게 다루는지 솔직하게 말하고 시작한다.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    @State private var location = LocationSetting(kind: .neighborhood, mode: .transit)
    @State private var allowSponsored = true
    @State private var analytics = true
    @State private var backup = true
    @State private var restoring = false

    private let lastPage = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro(
                        emoji: "💌",
                        title: "취향은 해 봐야 알아요",
                        text: "\"뭐 좋아해?\"에 답하기 어려운 건 취향이 없어서가 아니라, 해 본 게 적고 돌아볼 틈이 없어서예요."
                    )
                    .overlay(alignment: .bottom) {
                        if model.backupAvailable {
                            Button(restoring ? "가져오는 중…" : "전에 쓰던 엽서가 있어요 · iCloud에서 가져오기") {
                                Task {
                                    restoring = true
                                    _ = await model.restoreFromBackup()
                                    restoring = false
                                }
                            }
                            .font(.footnote)
                            .disabled(restoring)
                            .padding(.bottom, 40)
                        }
                    }
                    .tag(0)
                    intro(
                        emoji: "📮",
                        title: "해 보면 엽서 한 장",
                        text: "매주 작은 웰니스 실험 세 장을 받아요. 해 보고 사진과 느낌을 남기면 엽서가 되고, 구역마다 우표가 모여요.\n\n돈, 에너지, 시간은 매주 물어보고 거기에 맞춰 골라요."
                    ).tag(1)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("어디서 실험할까요?").font(.title2.bold())
                            Text("오가는 시간까지 따져서 실험을 고르려고 물어요.")
                                .foregroundStyle(Theme.muted)
                            LocationPicker(setting: $location)
                        }
                        .padding(24)
                    }
                    .tag(2)
                    adPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < lastPage {
                        withAnimation { page += 1 }
                    } else {
                        model.finishOnboarding(location: location, allowSponsored: allowSponsored, analytics: analytics && model.canSendAnalytics, backup: backup && model.backupAvailable)
                    }
                } label: {
                    Text(page < lastPage ? "다음" : "시작하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(page == 2 && location.kind != .none && location.region == nil)
                .padding(24)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
        }
    }

    private func intro(emoji: String, title: String, text: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Text(emoji).font(.system(size: 72))
            Text(title).font(.title.bold()).multilineTextAlignment(.center)
            Text(text).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var adPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("🎟️").font(.system(size: 64)).frame(maxWidth: .infinity)
            Text("광고 실험도 있어요").font(.title.bold()).frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                Label("요가 스튜디오, 찻집, 공방 같은 곳이 혜택과 함께 실험을 소개해요.", systemImage: "gift")
                Label("항상 '광고'라고 적혀 있고, 한 번에 많아야 한 장이에요. 이번 주 예산과 시간 안에서만 보여요.", systemImage: "tag")
                Label("내 기록, 예산, 위치는 광고주에게 가지 않아요. 무엇을 보여 줄지는 이 폰 안에서 골라요.", systemImage: "lock")
            }
            .font(.callout)
            .foregroundStyle(Theme.muted)
            VStack(alignment: .leading, spacing: 12) {
                Toggle("광고 실험도 받기", isOn: $allowSponsored)
                if model.backupAvailable {
                    Toggle("내 iCloud에 엽서 백업", isOn: $backup)
                }
                if model.canSendAnalytics {
                    Toggle("익명 주간 숫자 보내기", isOn: $analytics)
                    Text("체크인 여부와 엽서 수 같은 숫자만. 누가, 무엇을, 어디서 했는지는 보내지 않아요.")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
            .card()
            Text("설정에서 언제든 바꿀 수 있어요.").font(.footnote).foregroundStyle(Theme.muted)
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

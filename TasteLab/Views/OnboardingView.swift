import SwiftUI
import TasteCore

/// 처음 한 번. 앱이 무엇인지, 광고를 어떻게 다루는지 솔직하게 말하고 시작한다.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    @State private var allowSponsored = true

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                intro(
                    emoji: "🧪",
                    title: "취향은 해 봐야 알아요",
                    body: "\"뭐 좋아해?\"에 답하기 어려운 건 취향이 없어서가 아니라, 해 본 게 적고 돌아볼 틈이 없어서예요."
                ).tag(0)
                intro(
                    emoji: "🃏",
                    title: "매주 작은 실험 세 장",
                    body: "하루 안에, 돈 거의 안 들이고 할 수 있는 실험이에요. 해 보고 10초만 느낌을 남기면 취향 지도가 밝혀져요.\n\n세 장 중 한 장은 늘 처음 가 보는 쪽에서 와요. 이미 좋아하는 것만 권하지 않아요."
                ).tag(1)
                adPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    model.finishOnboarding(allowSponsored: allowSponsored)
                }
            } label: {
                Text(page < 2 ? "다음" : "첫 실험 받기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(24)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
    }

    private func intro(emoji: String, title: String, body: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Text(emoji).font(.system(size: 72))
            Text(title).font(.title.bold()).multilineTextAlignment(.center)
            Text(body).font(.body).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
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
                Label("공방, 체험 수업 같은 곳이 할인 혜택과 함께 실험을 소개해요.", systemImage: "gift")
                Label("광고 실험에는 항상 '광고'라고 적혀 있고, 한 번에 많아야 한 장이에요.", systemImage: "tag")
                Label("내 기록은 광고주에게 가지 않아요. 무엇을 보여 줄지는 이 폰 안에서 골라요.", systemImage: "lock")
            }
            .font(.callout)
            .foregroundStyle(Theme.muted)
            Toggle("광고 실험도 받기", isOn: $allowSponsored)
                .card()
            Text("나중에 설정에서 언제든 바꿀 수 있어요.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

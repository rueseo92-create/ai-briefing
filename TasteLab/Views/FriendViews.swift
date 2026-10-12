import SwiftUI
import TasteCore

/// 친구가 보낸 "같이 해 볼래?" 링크를 열었을 때.
struct InviteSheet: View {
    let invite: Invite
    let onAdded: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var result: AppModel.InviteResult?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("💌 \(invite.senderName)님이 같이 해 보자고 했어요").font(.title3.bold())
                if let experiment = invite.experiment(in: model.catalog) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(experiment.domain.emoji) \(experiment.domain.stampName)").font(.caption).foregroundStyle(Theme.muted)
                        Text(experiment.title).font(.headline)
                        Text(experiment.detail).font(.callout)
                        Text(Formats.time(minutes: experiment.minutes, travel: model.travelMinutes(experiment)) + " · " + Formats.cost(experiment.effectiveCost))
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                    .card()

                    if !model.saved.onboarded {
                        Text("먼저 앱을 시작해 주세요. 시작한 뒤 링크를 다시 열면 이번 주 실험에 넣을 수 있어요.")
                            .foregroundStyle(Theme.muted)
                    } else if let result {
                        Text(message(result)).font(.callout.weight(.semibold))
                        Button("이번 주 실험 보기") {
                            onAdded()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            result = model.accept(invite)
                        } label: {
                            Text("이번 주 실험에 넣기").frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        Text("엽서를 만들 때 '\(invite.senderName)'와 함께 했다고 남길 수 있어요.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                } else {
                    Text("이 실험을 찾을 수 없어요. 앱을 최신 버전으로 업데이트해 보세요.")
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
            }
            .padding(24)
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func message(_ result: AppModel.InviteResult) -> String {
        switch result {
        case .added: "이번 주 실험에 넣었어요."
        case .alreadyThisWeek: "이미 이번 주 실험에 있어요. 함께하는 걸로 표시했어요."
        case .alreadyTried: "이미 해 본 실험이에요. 이번엔 친구와 함께 다시 해 봐도 좋아요."
        case .unknownExperiment: "이 실험을 찾을 수 없어요."
        }
    }
}

/// "같이 하자고 보내기". 링크에는 실험 id와 (적었다면) 내 이름만 담긴다.
struct InviteShareButton: View {
    let experiment: Experiment
    @Environment(AppModel.self) private var model

    var body: some View {
        let invite = model.invite(for: experiment)
        ShareLink(item: invite.url, subject: Text("같이 해 볼래?"), message: Text(invite.message(for: experiment))) {
            Label("친구에게 같이 하자고 보내기", systemImage: "person.2.wave.2")
        }
        .buttonStyle(.bordered)
    }
}

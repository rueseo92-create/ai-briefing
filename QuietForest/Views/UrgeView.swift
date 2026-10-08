import SwiftUI
import ForestCore

/// 참기 버튼을 누른 뒤의 화면. 충동이 지나갈 때까지 같이 버틴다.
struct UrgeView: View {
    @Environment(AppModel.self) private var model
    @State private var cheerMessage: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            VStack(spacing: 24) {
                if let urge = model.urge, let habit = model.habit {
                    let finished = urge.isFinished(at: now)

                    Text(finished ? "버텼어요" : "조금만 버텨요")
                        .font(.title.bold())
                        .padding(.top, 24)

                    ZStack {
                        Circle()
                            .stroke(Theme.ground, lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: urge.progress(at: now))
                            .stroke(Theme.leaf, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 8) {
                            TreeView(stage: habit.stage(at: now), isWilting: habit.isWilting(at: now), isSwaying: !finished)
                                .frame(width: 140, height: 140)
                            Text(Format.countdown(urge.remaining(at: now)))
                                .font(.system(size: 40, weight: .semibold, design: .rounded).monospacedDigit())
                        }
                    }
                    .frame(width: 280, height: 280)

                    if !habit.reason.isEmpty {
                        VStack(spacing: 6) {
                            Text("내가 끊는 이유").font(.caption).foregroundStyle(Theme.muted)
                            Text(habit.reason).font(.title3).multilineTextAlignment(.center)
                        }
                        .card()
                    }

                    Text(finished
                         ? "충동은 지나갔어요. 숲에 기록해 둘게요."
                         : "충동은 보통 몇 분이면 지나가요. 숲의 다른 사람들도 지금 당신의 나무가 흔들리는 걸 보고 있어요.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.muted)

                    Spacer()

                    if finished {
                        Button {
                            model.endUrge(succeeded: true)
                        } label: {
                            Text("버텼어요 🌱").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("그만 보기") { model.endUrge(succeeded: false) }
                            .foregroundStyle(Theme.muted)
                    }
                    Button("다시 했어요") { model.recordSlip() }
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .overlay(alignment: .top) {
            if let cheerMessage {
                Text(cheerMessage)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.water.opacity(0.15), in: Capsule())
                    .foregroundStyle(Theme.water)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .task {
            // 참는 동안 물방울이 오는지 자주 확인한다.
            while !Task.isCancelled {
                await model.pollCheers()
                try? await Task.sleep(for: .seconds(8))
            }
        }
        .onChange(of: model.incomingCheers) { _, count in
            guard let count, count > 0 else { return }
            model.incomingCheers = nil
            showCheer(count == 1 ? "지금 누군가 당신에게 물을 줬어요 💧" : "지금 \(count)명이 당신에게 물을 줬어요 💧")
        }
        .sensoryFeedback(.success, trigger: cheerMessage)
    }

    private func showCheer(_ text: String) {
        withAnimation { cheerMessage = text }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { cheerMessage = nil }
        }
    }
}

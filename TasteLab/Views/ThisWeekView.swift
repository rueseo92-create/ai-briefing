import SwiftUI
import TasteCore

/// 이번 주 실험 세 장.
struct ThisWeekView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false
    @State private var path: [Experiment] = []

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("하나만 해도 충분해요. 마음이 안 가면 다른 걸로 바꿔요.")
                        .font(.callout)
                        .foregroundStyle(Theme.muted)

                    ForEach(model.picks) { pick in
                        // 카드 안의 "다른 걸로" 버튼이 먼저 눌리게, 링크 대신 탭으로 연다.
                        PickCard(pick: pick, entry: model.entry(for: pick.experiment)) {
                            withAnimation { model.swap(pick) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { path.append(pick.experiment) }
                        .accessibilityAddTraits(.isButton)
                    }

                    if model.picks.isEmpty {
                        Text("새 실험을 준비하고 있어요.")
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }

                    if model.allPicksDone {
                        VStack(spacing: 10) {
                            Text("이번 주 실험을 다 해 봤어요 🎉").font(.headline)
                            Button("처음 가 보는 쪽에서 한 장 더") {
                                withAnimation { model.addOneMore() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .card()
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("이번 주 실험")
            .navigationDestination(for: Experiment.self) { ExperimentDetailView(experiment: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("설정")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $model.justUnlockedSummary) {
                NavigationStack(path: $path) { SummarySheet() }
                    .presentationDetents([.large])
            }
            .task { model.refreshWeekIfNeeded() }
        }
    }
}

struct PickCard: View {
    let pick: Pick
    let entry: Entry?
    let onSwap: () -> Void

    var body: some View {
        let experiment = pick.experiment
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Chip(text: pick.slot.title, color: Theme.slotColor(pick.slot))
                if experiment.isSponsored { Chip(text: "광고", color: Theme.ad) }
                if experiment.kit != nil { Chip(text: "키트", color: Theme.kit) }
                Spacer()
                Text("\(experiment.domain.emoji) \(experiment.domain.title)")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            Text(experiment.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)
            Text(pick.reason)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            HStack {
                Label(Formats.minutes(experiment.minutes), systemImage: "clock")
                Label(experiment.place == .home ? "집에서" : "밖에서", systemImage: experiment.place == .home ? "house" : "figure.walk")
                Spacer()
                if let entry {
                    Text("\(entry.feeling.emoji) \(entry.feeling.title)")
                        .font(.footnote.weight(.semibold))
                } else {
                    Button("다른 걸로", action: onSwap)
                        .font(.footnote)
                        .buttonStyle(.bordered)
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.muted)
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.slotColor(pick.slot).opacity(entry == nil ? 0.35 : 0), lineWidth: 1.5)
        )
        .opacity(entry == nil ? 1 : 0.75)
    }
}

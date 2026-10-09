import SwiftUI
import ForestCore

/// 모두의 숲. 보이는 건 자동 이름과 나무 모습뿐이고, 할 수 있는 건 물 주기뿐이다.
struct ForestView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: PublicTree?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 5)) { timeline in
                let now = timeline.date
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(now: now)
                        if model.forest.isEmpty {
                            Text("아직 숲이 조용해요.")
                                .foregroundStyle(Theme.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(model.forest) { tree in
                                    cell(tree, now: now)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("숲")
            .refreshable { await model.refreshForest() }
            .task {
                while !Task.isCancelled {
                    await model.refreshForest()
                    try? await Task.sleep(for: .seconds(20))
                }
            }
            .confirmationDialog(
                selected.map { "\($0.name)에게 물을 줄까요?" } ?? "",
                isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } }),
                titleVisibility: .visible,
                presenting: selected
            ) { tree in
                Button("💧 물 주기") { model.water(tree) }
                Button("취소", role: .cancel) {}
            } message: { _ in
                Text("누가 줬는지는 알려지지 않아요. 오늘 \(model.cheersLeft())방울 남았어요.")
            }
        }
    }

    private func header(now: Date) -> some View {
        let urging = ForestStats.urgingCount(model.forest, now: now)
        return VStack(alignment: .leading, spacing: 8) {
            Text(urging > 0 ? "지금 \(urging)명이 참고 있어요" : "숲이 고요해요")
                .font(.title2.bold())
            if let cohort = model.cohort, cohort.total > 1 {
                Text("당신과 같은 날 시작한 \(cohort.total)명 중 \(cohort.active)명이 아직 걷는 중")
                    .font(.callout)
                    .foregroundStyle(Theme.muted)
            }
            Text("흔들리는 나무는 지금 참는 중이에요. 오늘 줄 수 있는 물: 💧 \(model.cheersLeft(at: now))")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
    }

    private func cell(_ tree: PublicTree, now: Date) -> some View {
        let urging = tree.isUrging(at: now)
        let watered = model.hasWatered(tree, at: now)
        return Button {
            guard !watered, model.cheersLeft() > 0 else { return }
            selected = tree
        } label: {
            VStack(spacing: 6) {
                TreeView(stage: tree.stage, isWilting: tree.isWilting, isSwaying: urging)
                    .frame(height: 84)
                Text(tree.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 32, alignment: .top)
                if watered {
                    Text("💧 줬어요").font(.caption2).foregroundStyle(Theme.water)
                } else if urging {
                    Text("참는 중").font(.caption2.weight(.semibold)).foregroundStyle(Theme.water)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(urging ? Theme.water.opacity(0.1) : Theme.card)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(watered ? "이미 물을 줬어요" : "물 주기")
    }
}

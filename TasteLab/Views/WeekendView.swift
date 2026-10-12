import SwiftUI
import TasteCore

/// 주말에 해 볼 취미. 필요한 게 있으면 키트를 미리 받아 둔다.
struct WeekendView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let saturday = Weekend.upcomingSaturday(from: Date())
                    Text("이번 주말은 \(Formats.day(saturday))")
                        .font(.callout)
                        .foregroundStyle(Theme.muted)

                    if let plan = model.weekendPlan {
                        NavigationLink(value: plan) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🗓️ 이번 주말 계획").font(.caption.weight(.bold)).foregroundStyle(Theme.kit)
                                Text(plan.title).font(.title3.weight(.semibold))
                                if let kit = plan.kit {
                                    Text(Formats.kitLine(kit)).font(.footnote).foregroundStyle(Theme.muted)
                                }
                            }
                            .card()
                        }
                        .buttonStyle(.plain)
                    }

                    Text("나랑 맞을 것 같은 주말 키트").font(.headline).padding(.top, 4)
                    Text("이번 주 예산(\(model.checkIn.budget.title)) 안의 키트만 보여요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                    let ideas = model.weekendIdeas()
                    if ideas.isEmpty {
                        Text("이번 예산에 맞는 키트가 없어요. 이번 주 체크인에서 예산을 바꿀 수 있어요.").foregroundStyle(Theme.muted)
                    }
                    ForEach(ideas) { experiment in
                        NavigationLink(value: experiment) {
                            kitRow(experiment)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("키트는 공방·브랜드와 함께 준비해요. 주말 전에 받을 수 있는 마감 시각을 같이 알려 드려요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("주말")
            .navigationDestination(for: Experiment.self) { ExperimentDetailView(experiment: $0) }
        }
    }

    private func kitRow(_ experiment: Experiment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Chip(text: "\(experiment.domain.emoji) \(experiment.domain.stampName)", color: Theme.domainColor(experiment.domain))
                Chip(text: "키트", color: Theme.kit)
                if experiment.isSponsored { Chip(text: "광고", color: Theme.ad) }
            }
            Text(experiment.title).font(.headline)
            if let kit = experiment.kit {
                HStack {
                    Text(kit.name)
                    Spacer()
                    Text(Formats.won(kit.price)).monospacedDigit()
                }
                .font(.callout)
                Text(Formats.kitLine(kit)).font(.caption).foregroundStyle(Theme.kit)
            }
        }
        .card()
    }
}

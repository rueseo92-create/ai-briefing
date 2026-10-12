import SwiftUI
import TasteCore

/// 취향 지도. 해 볼수록 지역이 밝혀진다.
struct MapView: View {
    @Environment(AppModel.self) private var model

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    let profile = model.profile
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Domain.allCases) { domain in
                            tile(domain, stat: profile.stat(domain))
                        }
                    }

                    if model.summary != nil {
                        NavigationLink {
                            SummarySheet()
                        } label: {
                            Label("내 취향 정리 보기", systemImage: "sparkles")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        let count = model.journal.entries.count
                        VStack(alignment: .leading, spacing: 8) {
                            Text("실험을 \(Insight.minimumEntries)번 해 보면 취향 정리가 나와요")
                                .font(.headline)
                            ProgressView(value: Double(count), total: Double(Insight.minimumEntries))
                            Text("\(count) / \(Insight.minimumEntries)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Theme.muted)
                        }
                        .card()
                    }

                    if !profile.topTags().isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("좋았던 이유").font(.headline)
                            ForEach(profile.topTags(5), id: \.self) { tag in
                                HStack {
                                    Text(tag.title)
                                    Spacer()
                                    Text(String(repeating: "●", count: min(5, profile.tagScores[tag] ?? 0)))
                                        .foregroundStyle(Theme.accent)
                                }
                                .font(.callout)
                            }
                        }
                        .card()
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("취향 지도")
        }
    }

    private func tile(_ domain: Domain, stat: DomainStat) -> some View {
        let color = Theme.domainColor(domain)
        let state = stat.state
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.tried == 0 ? "☁️" : domain.emoji).font(.title2)
                Spacer()
                if state == .favorite { Text("💛") }
            }
            Text(domain.title).font(.headline)
            Text(state.title).font(.caption).foregroundStyle(Theme.muted)
            if stat.tried > 0 {
                Text("\(stat.tried)번 해 봄 · 좋았던 \(stat.liked)번")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.06 + 0.3 * stat.light))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(color.opacity(stat.tried == 0 ? 0.15 : 0.5), style: StrokeStyle(lineWidth: 1.5, dash: stat.tried == 0 ? [5, 4] : []))
        )
        .accessibilityElement(children: .combine)
    }
}

/// 취향 정리. 다섯 번째 기록 직후에 한 번 뜨고, 지도에서 언제든 볼 수 있다.
struct SummarySheet: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            if let summary = model.summary {
                VStack(spacing: 20) {
                    TasteCard(summary: summary, profile: model.profile)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(summary.lines, id: \.self) { line in
                            Text("· \(line)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    if let image = TasteCard.render(summary: summary, profile: model.profile) {
                        ShareLink(item: image, preview: SharePreview("나의 취향 카드", image: image)) {
                            Label("취향 카드 저장·공유", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Text("공유하는 건 이 카드뿐이에요. 실험 기록은 이 폰에만 있어요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationTitle("내 취향 정리")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 공유용 취향 카드.
struct TasteCard: View {
    let summary: TasteSummary
    let profile: TasteProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("나의 취향 카드").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.8))
            Text(summary.headline).font(.title2.bold()).foregroundStyle(.white)
            HStack(spacing: 6) {
                ForEach(summary.topTags, id: \.self) { tag in
                    Text(tag.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.2), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            HStack(spacing: 4) {
                ForEach(Domain.allCases) { domain in
                    Text(profile.stat(domain).tried == 0 ? "☁️" : domain.emoji)
                        .opacity(0.4 + 0.6 * profile.stat(domain).light)
                }
            }
            .font(.title3)
            Text("취향 실험실").font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .padding(22)
        .frame(width: 320, alignment: .leading)
        .background(
            LinearGradient(colors: [Color(light: 0x6A55C9, dark: 0x5845B0), Color(light: 0xC2557A, dark: 0xA8466A)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    @MainActor
    static func render(summary: TasteSummary, profile: TasteProfile) -> Image? {
        let renderer = ImageRenderer(content: TasteCard(summary: summary, profile: profile).padding(12))
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }
}

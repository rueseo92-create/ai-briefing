import SwiftUI
import TasteCore

/// 나 탭. 나에게 온 편지(취향 정리), 좋았던 이유, 설정.
struct MeView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let summary = model.summary {
                        NavigationLink {
                            LetterView()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("나에게 온 편지", systemImage: "envelope.open").font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
                                Text(summary.headline).font(.title3.weight(.semibold))
                                Text("열어 보기").font(.footnote).foregroundStyle(Theme.muted)
                            }
                            .card()
                        }
                        .buttonStyle(.plain)
                    } else {
                        let count = model.journal.entries.count
                        VStack(alignment: .leading, spacing: 8) {
                            Text("엽서 \(Insight.minimumEntries)장이 모이면 나에게 편지가 와요").font(.headline)
                            ProgressView(value: Double(count), total: Double(Insight.minimumEntries))
                            Text("\(count) / \(Insight.minimumEntries)").font(.footnote.monospacedDigit()).foregroundStyle(Theme.muted)
                        }
                        .card()
                    }

                    let profile = model.profile
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("구역별로 해 본 것").font(.headline)
                        ForEach(Domain.allCases) { domain in
                            let stat = profile.stat(domain)
                            HStack {
                                Text("\(domain.emoji) \(domain.title)")
                                Spacer()
                                Text(stat.tried == 0 ? "아직" : "\(stat.tried)장 · \(stat.state.title)")
                                    .foregroundStyle(Theme.muted)
                            }
                            .font(.callout)
                        }
                    }
                    .card()
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("나")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("설정")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }
}

/// 나에게 온 편지. 엽서 다섯 장부터 열린다.
struct LetterView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            if let summary = model.summary {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("나에게").font(.headline)
                        Text("엽서 \(model.journal.entries.count)장을 읽어 보니, 너는 \(summary.headline)이야.")
                            .font(.title3.weight(.semibold))
                        ForEach(summary.lines, id: \.self) { line in
                            Text(line)
                        }
                        if let frontier = summary.nextFrontier {
                            Text("다음엔 ‘\(frontier.stampName)’ 쪽에도 가 볼까?").foregroundStyle(Theme.muted)
                        }
                        Text("— 취향 엽서").font(.footnote).foregroundStyle(Theme.muted).frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(22)
                    .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.muted.opacity(0.2)))

                    TasteCard(summary: summary, stamps: model.stamps)
                    if let image = TasteCard.render(summary: summary, stamps: model.stamps) {
                        ShareLink(item: image, preview: SharePreview("나의 취향 카드", image: image)) {
                            Label("취향 카드 저장·공유", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Text("공유하는 건 이 카드뿐이에요. 엽서와 기록은 이 폰에만 있어요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationTitle("나에게 온 편지")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 공유용 취향 카드.
struct TasteCard: View {
    let summary: TasteSummary
    let stamps: [StampState]

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
                ForEach(stamps) { stamp in
                    Text(stamp.earned ? stamp.domain.emoji : "·").opacity(stamp.earned ? 1 : 0.5)
                }
            }
            .font(.title3)
            Text("취향 엽서").font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .padding(22)
        .frame(width: 320, alignment: .leading)
        .background(
            LinearGradient(colors: [Color(light: 0x6A55C9, dark: 0x5845B0), Color(light: 0xC2557A, dark: 0xA8466A)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    @MainActor
    static func render(summary: TasteSummary, stamps: [StampState]) -> Image? {
        let renderer = ImageRenderer(content: TasteCard(summary: summary, stamps: stamps).padding(12))
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }
}

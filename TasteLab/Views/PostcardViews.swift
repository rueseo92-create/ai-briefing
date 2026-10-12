import SwiftUI
import UIKit
import TasteCore

/// 엽서 한 장. 누르면 뒤집어서 뒷면(이유, 메모)을 본다.
struct PostcardView: View {
    let entry: Entry
    let photos: PhotoStore
    @State private var flipped = false

    var body: some View {
        ZStack {
            PostcardFront(entry: entry, image: entry.photo.flatMap(photos.image(named:)))
                .opacity(flipped ? 0 : 1)
            PostcardBack(entry: entry)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture { withAnimation(.spring(duration: 0.5)) { flipped.toggle() } }
        .accessibilityElement(children: .combine)
        .accessibilityHint("두 번 눌러서 뒷면 보기")
    }
}

struct PostcardFront: View {
    let entry: Entry
    let image: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1.5, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZoneArt(domain: entry.domain)
                }
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title).font(.headline).lineLimit(2)
                    Text(entry.at.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ko_KR"))))
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 3)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom))
            }
            .overlay(alignment: .topTrailing) {
                StampMark(domain: entry.domain, earned: true, gold: false, size: 54).padding(10)
            }
            .overlay(alignment: .topLeading) {
                if let stamp = entry.feeling.stamp {
                    FeelingStamp(text: stamp).padding(16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.6), lineWidth: 4))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    /// 공유용 이미지.
    @MainActor
    static func render(entry: Entry, image: UIImage?) -> Image? {
        let renderer = ImageRenderer(content: PostcardFront(entry: entry, image: image).frame(width: 600).padding(16))
        renderer.scale = 2
        return renderer.uiImage.map { Image(uiImage: $0) }
    }
}

struct PostcardBack: View {
    let entry: Entry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.note.isEmpty ? "메모 없음" : entry.note)
                    .font(.callout)
                    .foregroundStyle(entry.note.isEmpty ? Theme.muted : Theme.ink)
                Spacer(minLength: 0)
                if !entry.why.isEmpty {
                    Text(entry.why.map(\.title).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
            Rectangle().fill(Theme.muted.opacity(0.3)).frame(width: 1)
            VStack(alignment: .leading, spacing: 10) {
                StampMark(domain: entry.domain, earned: true, gold: false, size: 44)
                Text("나에게").font(.caption.weight(.semibold))
                if let friend = entry.with {
                    Text("함께: \(friend)").font(.caption)
                }
                Text("\(entry.feeling.emoji) \(entry.feeling.title)").font(.caption)
                Text(entry.domain.title).font(.caption2).foregroundStyle(Theme.muted)
            }
            .frame(width: 96, alignment: .leading)
        }
        .padding(16)
        .aspectRatio(1.5, contentMode: .fit)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.muted.opacity(0.2)))
        .foregroundStyle(Theme.ink)
    }
}

/// 사진이 없을 때의 구역 그림.
struct ZoneArt: View {
    let domain: Domain

    var body: some View {
        let color = Theme.domainColor(domain)
        ZStack {
            LinearGradient(colors: [color.opacity(0.85), color.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(domain.emoji).font(.system(size: 72)).opacity(0.9)
        }
    }
}

/// 구역 우표. 테두리를 점선으로 그려 우표 느낌을 낸다.
struct StampMark: View {
    let domain: Domain
    let earned: Bool
    let gold: Bool
    var size: CGFloat = 64

    var body: some View {
        VStack(spacing: 2) {
            Text(earned ? domain.emoji : "?").font(.system(size: size * 0.38))
            Text(domain.stampName).font(.system(size: max(9, size * 0.15), weight: .semibold)).lineLimit(1)
        }
        .foregroundStyle(earned ? Theme.ink : Theme.muted)
        .frame(width: size, height: size * 1.15)
        .background(earned ? Theme.paper : Theme.card, in: RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(gold ? Theme.gold : (earned ? Theme.domainColor(domain) : Theme.muted.opacity(0.4)),
                              style: StrokeStyle(lineWidth: gold ? 3 : 2, dash: [3, 2]))
        )
        .opacity(earned ? 1 : 0.6)
    }
}

/// 느낌 도장. "좋았어요", "다음엔 다르게"
struct FeelingStamp: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(Theme.stampInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(Circle().fill(.white.opacity(0.7)))
            .overlay(Circle().stroke(Theme.stampInk, lineWidth: 2.5))
            .overlay(Circle().inset(by: 4).stroke(Theme.stampInk.opacity(0.6), lineWidth: 1))
            .rotationEffect(.degrees(-12))
            .opacity(0.9)
    }
}

/// 여덟 구역 우표판.
struct StampBoard: View {
    let stamps: [StampState]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("우표").font(.headline)
                Spacer()
                Text("\(stamps.filter(\.earned).count) / \(stamps.count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                ForEach(stamps) { stamp in
                    StampMark(domain: stamp.domain, earned: stamp.earned, gold: stamp.isGold, size: 64)
                        .accessibilityLabel("\(stamp.domain.stampName) 우표, \(stamp.earned ? (stamp.isGold ? "금색" : "받음") : "아직 없음")")
                }
            }
            Text("한 구역에서 '좋았어요'가 \(StampState.goldLikes)번이면 금색 우표가 돼요.")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .card()
    }
}

/// 엽서를 만든 직후. 도장이 쾅 찍힌다.
struct PostcardReveal: View {
    let entry: Entry
    let stamps: [StampState]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var stamped = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("엽서가 도착했어요").font(.title2.bold())
                    PostcardView(entry: entry, photos: model.photos)
                        .scaleEffect(stamped ? 1 : 1.08)
                        .rotationEffect(.degrees(stamped ? -1.5 : 0))

                    ForEach(stamps) { stamp in
                        HStack(spacing: 12) {
                            StampMark(domain: stamp.domain, earned: true, gold: stamp.isGold, size: 48)
                            Text(stamp.isGold ? "‘\(stamp.domain.stampName)’ 우표가 금색이 됐어요" : "새 우표: ‘\(stamp.domain.stampName)’")
                                .font(.callout.weight(.semibold))
                            Spacer()
                        }
                        .card()
                    }

                    if let image = PostcardFront.render(entry: entry, image: entry.photo.flatMap(model.photos.image(named:))) {
                        ShareLink(item: image, preview: SharePreview(entry.title, image: image)) {
                            Label("엽서 저장·공유", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if model.justUnlockedSummary {
                        NavigationLink {
                            LetterView()
                        } label: {
                            Label("나에게 편지가 왔어요", systemImage: "envelope.open")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .simultaneousGesture(TapGesture().onEnded { model.justUnlockedSummary = false })
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.2)) { stamped = true }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: stamped)
        }
    }
}

/// 엽서함 탭. 우표판과 모은 엽서.
struct PostcardBoxView: View {
    @Environment(AppModel.self) private var model

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    StampBoard(stamps: model.stamps)

                    Text("엽서 \(model.postcards.count)장").font(.headline)
                    if model.postcards.isEmpty {
                        Text("아직 엽서가 없어요. '이번 주'에서 실험 하나를 해 보고 엽서를 만들어 봐요.")
                            .foregroundStyle(Theme.muted)
                            .card()
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(model.postcards) { entry in
                            NavigationLink {
                                PostcardDetail(entry: entry)
                            } label: {
                                PostcardFront(entry: entry, image: entry.photo.flatMap(model.photos.image(named:)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("엽서함")
            .toolbar {
                if !model.postcards.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink { PrintPackView() } label: { Image(systemName: "printer") }
                            .accessibilityLabel("실물 엽서 인쇄")
                    }
                }
            }
        }
    }
}

struct PostcardDetail: View {
    let entry: Entry
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PostcardView(entry: entry, photos: model.photos)
                Text("엽서를 누르면 뒷면을 볼 수 있어요.").font(.footnote).foregroundStyle(Theme.muted)
                if let image = PostcardFront.render(entry: entry, image: entry.photo.flatMap(model.photos.image(named:))) {
                    ShareLink(item: image, preview: SharePreview(entry.title, image: image)) {
                        Label("엽서 저장·공유", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                if let experiment = model.catalog.first(where: { $0.id == entry.experimentID }) {
                    InviteShareButton(experiment: experiment)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

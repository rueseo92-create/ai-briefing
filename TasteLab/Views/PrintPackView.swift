import SwiftUI
import UIKit
import TasteCore

/// 실물 엽서 인쇄. 계절마다 모은 엽서 중 8장을 골라 인쇄용 PDF(148×100mm, 앞·뒷면)로 만든다.
struct PrintPackView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var season: SeasonKey?
    @State private var chosen: [UUID] = []
    @State private var pdf: URL?
    @State private var making = false

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        let seasons = PrintPack.seasons(model.journal.entries)
        let current = season ?? seasons.first?.key
        let entries = current.map { key in model.journal.entries.filter { SeasonKey($0.at) == key } } ?? []

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("계절마다 모은 엽서 중 \(PrintPack.size)장까지 골라 진짜 엽서로 인쇄해요. 앞면은 사진, 뒷면은 메모와 우표예요.")
                    .font(.callout)
                    .foregroundStyle(Theme.muted)

                if !seasons.isEmpty {
                    Picker("계절", selection: Binding(get: { current }, set: { season = $0; chosen = []; pdf = nil })) {
                        ForEach(seasons, id: \.key) { item in
                            Text("\(item.key.title) · \(item.count)장").tag(Optional(item.key))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Text("\(chosen.count) / \(PrintPack.size)장 골랐어요").font(.headline)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(entries) { entry in
                        let selected = chosen.contains(entry.id)
                        Button {
                            if selected {
                                chosen.removeAll { $0 == entry.id }
                            } else if chosen.count < PrintPack.size {
                                chosen.append(entry.id)
                            }
                            pdf = nil
                        } label: {
                            PostcardFront(entry: entry, image: entry.photo.flatMap(model.photos.image(named:)))
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(selected ? Theme.accent : .white)
                                        .padding(8)
                                }
                                .opacity(selected || chosen.count < PrintPack.size ? 1 : 0.5)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let pdf {
                    ShareLink(item: pdf) {
                        Label("인쇄용 PDF 저장·공유", systemImage: "doc.richtext").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    if let order = AppConfig.printOrderURL {
                        Button("인쇄 주문하기") { openURL(order) }
                            .buttonStyle(.bordered)
                    } else {
                        Text("PDF를 동네 인쇄소나 온라인 엽서 인쇄에 맡기면 돼요. 148×100mm, 앞·뒷면 순서예요.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                } else {
                    Button {
                        making = true
                        let selected = chosen.compactMap { id in entries.first { $0.id == id } }.sorted { $0.at < $1.at }
                        pdf = PostcardPrinter.makePDF(selected, photos: model.photos)
                        making = false
                    } label: {
                        Text(making ? "만드는 중…" : "인쇄용 PDF 만들기").frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(chosen.isEmpty || making)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationTitle("실물 엽서 인쇄")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if chosen.isEmpty, let key = current {
                chosen = PrintPack.suggest(model.journal.entries, for: key).map(\.id)
            }
        }
    }
}

/// 인쇄용 PDF. 엽서 한 장마다 앞면, 뒷면 두 쪽.
@MainActor
enum PostcardPrinter {
    /// 148 × 100 mm
    static let pageSize = CGSize(width: 148 / 25.4 * 72, height: 100 / 25.4 * 72)

    static func makePDF(_ entries: [Entry], photos: PhotoStore) -> URL? {
        // 그림을 먼저 다 만든 뒤 PDF에 그린다.
        var pages: [UIImage] = []
        for entry in entries {
            let image = entry.photo.flatMap(photos.image(named:))
            let front = ImageRenderer(content: PostcardFront(entry: entry, image: image).frame(width: pageSize.width))
            let back = ImageRenderer(content: PostcardBack(entry: entry).frame(width: pageSize.width).environment(\.colorScheme, .light))
            front.scale = 4
            back.scale = 4
            if let page = front.uiImage { pages.append(page) }
            if let page = back.uiImage { pages.append(page) }
        }
        guard !pages.isEmpty else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("취향엽서-인쇄-\(Int(Date().timeIntervalSince1970)).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        do {
            try renderer.writePDF(to: url) { context in
                for page in pages {
                    context.beginPage()
                    page.draw(in: CGRect(origin: .zero, size: pageSize))
                }
            }
            return url
        } catch {
            return nil
        }
    }
}

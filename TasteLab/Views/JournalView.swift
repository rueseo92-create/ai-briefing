import SwiftUI
import TasteCore

struct JournalView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                if model.journal.entries.isEmpty {
                    Text("아직 기록이 없어요. 이번 주 실험 하나를 해 보고 \"해 봤어요\"를 눌러요.")
                        .foregroundStyle(Theme.muted)
                }
                ForEach(model.journal.entries.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.feeling.emoji)
                            Text(entry.title).font(.headline)
                        }
                        HStack(spacing: 6) {
                            Text("\(entry.domain.emoji) \(entry.domain.title)")
                            if !entry.why.isEmpty {
                                Text("· " + entry.why.map(\.title).joined(separator: ", "))
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        if !entry.note.isEmpty {
                            Text(entry.note).font(.callout)
                        }
                        Text(Formats.day(entry.at)).font(.caption2).foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("기록")
        }
    }
}

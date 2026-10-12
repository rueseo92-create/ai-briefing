import SwiftUI
import UIKit
import TasteCore

struct ExperimentDetailView: View {
    let experiment: Experiment
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var reacting = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 6) {
                    Chip(text: "\(experiment.domain.emoji) \(experiment.domain.title)", color: Theme.domainColor(experiment.domain))
                    if experiment.isSponsored { Chip(text: "광고", color: Theme.ad) }
                    if experiment.kit != nil { Chip(text: "키트", color: Theme.kit) }
                }
                Text(experiment.title).font(.title.bold())
                Text(experiment.detail).font(.body)
                HStack(spacing: 16) {
                    Label(Formats.minutes(experiment.minutes), systemImage: "clock")
                    Label(experiment.place == .home ? "집에서" : "밖에서", systemImage: experiment.place == .home ? "house" : "figure.walk")
                }
                .font(.callout)
                .foregroundStyle(Theme.muted)

                if let sponsor = experiment.sponsor { sponsorCard(sponsor) }
                if let kit = experiment.kit { kitCard(kit) }

                if let entry = model.entry(for: experiment) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(entry.feeling.emoji) \(entry.feeling.title)").font(.headline)
                        if !entry.why.isEmpty {
                            Text(entry.why.map(\.title).joined(separator: " · ")).foregroundStyle(Theme.muted)
                        }
                        if !entry.note.isEmpty { Text(entry.note) }
                    }
                    .card()
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !model.hasTried(experiment) {
                Button {
                    reacting = true
                } label: {
                    Text("해 봤어요").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
        .sheet(isPresented: $reacting) {
            ReactionSheet(experiment: experiment)
                .presentationDetents([.medium, .large])
        }
    }

    private func sponsorCard(_ sponsor: Sponsorship) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎟️ \(sponsor.benefit)").font(.headline)
                Spacer()
                Chip(text: "광고", color: Theme.ad)
            }
            Text("\(sponsor.brand)에서 소개하는 실험이에요. 내 기록은 광고주에게 가지 않아요.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            if let code = sponsor.code {
                Button {
                    UIPasteboard.general.string = code
                    copied = true
                } label: {
                    Label(copied ? "복사했어요" : "혜택 코드 \(code) 복사", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            if let url = sponsor.url {
                Button("예약하러 가기") { openURL(url) }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.ad)
            }
            if let endsAt = sponsor.endsAt {
                Text("\(Formats.day(endsAt))까지").font(.caption).foregroundStyle(Theme.muted)
            }
        }
        .card()
    }

    private func kitCard(_ kit: Kit) -> some View {
        let planned = model.weekendPlan?.id == experiment.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📦 \(kit.name)").font(.headline)
                Spacer()
                Text(Formats.won(kit.price)).font(.headline.monospacedDigit())
            }
            ForEach(kit.contents, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle").font(.callout)
            }
            Text(Formats.kitLine(kit))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.kit)
            HStack {
                Button(planned ? "주말 계획에서 빼기" : "이번 주말에 해 볼래요") {
                    model.planWeekend(planned ? nil : experiment)
                }
                .buttonStyle(.bordered)
                if let url = kit.url {
                    Button("키트 주문하기") { openURL(url) }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.kit)
                }
            }
            if kit.url == nil {
                Text("예시 키트예요. 실제 판매처를 연결하면 주문 버튼이 생겨요.")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .card()
    }
}

/// 해 본 뒤 10초 기록.
struct ReactionSheet: View {
    let experiment: Experiment
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var feeling: Feeling?
    @State private var why: [Tag] = []
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("어땠어요?") {
                    HStack(spacing: 10) {
                        ForEach(Feeling.allCases, id: \.self) { option in
                            Button {
                                feeling = option
                            } label: {
                                VStack(spacing: 4) {
                                    Text(option.emoji).font(.largeTitle)
                                    Text(option.title).font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(feeling == option ? Theme.accent.opacity(0.18) : .clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let feeling, feeling != .meh {
                    Section(feeling == .liked ? "왜 좋았어요?" : "왜 별로였어요?") {
                        ForEach(experiment.tags) { tag in
                            Button {
                                if let index = why.firstIndex(of: tag) { why.remove(at: index) } else { why.append(tag) }
                            } label: {
                                HStack {
                                    Text(tag.title)
                                    Spacer()
                                    if why.contains(tag) { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
                                }
                            }
                            .foregroundStyle(Theme.ink)
                        }
                    }
                }

                Section("한 줄 메모 (선택)") {
                    TextField("예: 생각보다 시간이 빨리 갔다", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(experiment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        guard let feeling else { return }
                        model.record(experiment, feeling: feeling, why: feeling == .meh ? [] : why, note: note)
                        dismiss()
                    }
                    .disabled(feeling == nil)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: feeling)
    }
}

import SwiftUI
import UIKit
import TasteCore

struct ExperimentDetailView: View {
    let experiment: Experiment
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var reacting = false
    @State private var copied = false
    /// 기록 시트가 닫힌 뒤에 엽서를 보여 준다. 시트 두 개를 겹쳐 띄우지 않으려고.
    @State private var reveal: Entry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 6) {
                    Chip(text: "\(experiment.domain.emoji) \(experiment.domain.stampName) · \(experiment.domain.title)", color: Theme.domainColor(experiment.domain))
                    if experiment.isSponsored { Chip(text: "광고", color: Theme.ad) }
                    if experiment.kit != nil { Chip(text: "키트", color: Theme.kit) }
                }
                Text(experiment.title).font(.title.bold())
                Text(experiment.detail)
                VStack(alignment: .leading, spacing: 6) {
                    Label(Formats.time(minutes: experiment.minutes, travel: model.travelMinutes(experiment)), systemImage: "clock")
                    Label(Formats.cost(experiment.effectiveCost), systemImage: "wonsign.circle")
                    Label(placeText, systemImage: experiment.place.isHome ? "house" : "figure.walk")
                    if experiment.needsCompany { Label("누군가와 함께 해요", systemImage: "person.2") }
                }
                .font(.callout)
                .foregroundStyle(Theme.muted)

                if let venue = model.recommender.venue(for: experiment) {
                    VenueMapCard(venue: venue, origin: model.location.origin, travel: model.travelMinutes(experiment))
                } else if case .find(let need) = experiment.place {
                    Text("근처 \(need.title): 아직 지도에서 못 찾았어요. 이번 주 화면의 동네 지도에서 다시 찾아볼 수 있어요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .card()
                }

                if let sponsor = experiment.sponsor { sponsorCard(sponsor) }
                if let kit = experiment.kit { kitCard(kit) }

                if let entry = model.entry(for: experiment) {
                    PostcardView(entry: entry, photos: model.photos)
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
                    Text("해 봤어요 · 엽서 만들기").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
        .sheet(isPresented: $reacting, onDismiss: {
            reveal = model.freshPostcard
            model.freshPostcard = nil
        }) {
            ReactionSheet(experiment: experiment)
        }
        .sheet(item: $reveal) { entry in
            PostcardReveal(entry: entry, stamps: model.freshStamps)
        }
    }

    private var placeText: String {
        switch experiment.place {
        case .home: "집에서"
        case .nearby: "동네 어디서나"
        case .venue(let venue): venue.name
        case .find(let need): model.recommender.venue(for: experiment)?.name ?? need.title
        }
    }

    private func sponsorCard(_ sponsor: Sponsorship) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎟️ \(sponsor.benefit)").font(.headline)
                Spacer()
                Chip(text: "광고", color: Theme.ad)
            }
            Text("원래 \(Formats.won(experiment.cost)) → 혜택 받으면 \(Formats.won(sponsor.priceAfterBenefit))")
                .font(.callout.monospacedDigit())
            Text("\(sponsor.brand)에서 소개하는 실험이에요. 내 기록, 예산, 위치는 광고주에게 가지 않아요.")
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

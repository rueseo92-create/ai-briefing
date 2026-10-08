import SwiftUI
import ForestCore

struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    private enum Step: Int, CaseIterable {
        case welcome, choose, when, details, name
    }

    @State private var step: Step = .welcome
    @State private var kind: HabitKind?
    @State private var customTitle = ""
    @State private var startsNow = true
    @State private var lastTime = Date()
    @State private var dailyCost = ""
    @State private var reason = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if step != .welcome {
                ProgressView(value: Double(step.rawValue), total: Double(Step.allCases.count - 1))
                    .tint(Theme.leaf)
            }
            Group {
                switch step {
                case .welcome: welcome
                case .choose: choose
                case .when: when
                case .details: details
                case .name: name
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Button(action: advance) {
                Text(step == .name ? "숲으로 들어가기" : "다음")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdvance)
        }
        .padding(24)
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .animation(.easeInOut, value: step)
    }

    // MARK: - 단계

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            TreeView(stage: .sapling)
                .frame(width: 140, height: 140)
                .padding(.top, 40)
            Text("그만두는 사람들의 숲")
                .font(.largeTitle.bold())
            Text("무언가를 끊으려는 사람들이 각자 나무 한 그루씩 키우는 곳이에요.")
                .font(.title3)
                .foregroundStyle(Theme.muted)
            VStack(alignment: .leading, spacing: 10) {
                Label("채팅도, 댓글도, 프로필도 없어요", systemImage: "speaker.slash")
                Label("무엇을 끊는지는 아무도 몰라요", systemImage: "lock")
                Label("할 일이나 집중 타이머는 없어요. 오직 끊는 것만", systemImage: "leaf")
            }
            .font(.callout)
            .foregroundStyle(Theme.muted)
        }
    }

    private var choose: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("무엇을 끊나요?")
                .font(.title.bold())
            Text("이 폰에만 저장돼요. 숲에는 절대 보이지 않아요.")
                .foregroundStyle(Theme.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(HabitKind.allCases) { option in
                    Button {
                        kind = option
                    } label: {
                        HStack {
                            Text(option.emoji)
                            Text(option.title).fontWeight(.medium)
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(kind == option ? Theme.leaf.opacity(0.18) : Theme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(kind == option ? Theme.leaf : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            if kind == .custom {
                TextField("예: 커피, 배달음식", text: $customTitle)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var when: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("마지막으로 한 건 언제예요?")
                .font(.title.bold())
            Picker("", selection: $startsNow) {
                Text("지금부터 시작").tag(true)
                Text("이미 참고 있어요").tag(false)
            }
            .pickerStyle(.segmented)
            if !startsNow {
                DatePicker("마지막으로 한 때", selection: $lastTime, in: ...Date())
                    .datePickerStyle(.graphical)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("조금만 더 알려 주세요")
                .font(.title.bold())
            Text("둘 다 건너뛰어도 괜찮아요.")
                .foregroundStyle(Theme.muted)
            VStack(alignment: .leading, spacing: 6) {
                Text("하루에 보통 얼마 썼나요?").font(.headline)
                TextField("예: 4500", text: $dailyCost)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Text("아낀 돈을 계산하는 데만 써요.").font(.caption).foregroundStyle(Theme.muted)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("왜 끊고 싶나요?").font(.headline)
                TextField("예: 아이랑 오래 놀아 주고 싶어서", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                Text("참기 힘들 때 다시 보여 드릴게요.").font(.caption).foregroundStyle(Theme.muted)
            }
        }
    }

    private var name: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 20)
            TreeView(stage: .seed)
                .frame(width: 160, height: 160)
            Text("당신의 나무")
                .foregroundStyle(Theme.muted)
            Text(model.treeName)
                .font(.largeTitle.bold())
            Text("이름은 숲이 정해 줘요. 바꿀 수 없어요.")
                .font(.callout)
                .foregroundStyle(Theme.muted)
            Text("숲의 다른 사람들은 이 이름과 나무 모습만 볼 수 있어요. 무엇을 끊는지, 며칠째인지는 당신만 알아요.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
                .card()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 진행

    private var canAdvance: Bool {
        switch step {
        case .choose:
            guard let kind else { return false }
            return kind != .custom || !customTitle.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return true
        }
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        step = next
    }

    private func finish() {
        guard let kind else { return }
        let digits = dailyCost.filter(\.isNumber)
        let habit = Habit(
            kind: kind,
            customTitle: kind == .custom ? customTitle : nil,
            startedAt: startsNow ? Date() : min(lastTime, Date()),
            dailyCost: Int(digits) ?? 0,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        model.begin(with: habit)
    }
}

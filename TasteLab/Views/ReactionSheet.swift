import SwiftUI
import PhotosUI
import TasteCore

/// 해 본 뒤 10초 기록. 느낌, 이유, 사진과 메모(선택) → 엽서 한 장.
struct ReactionSheet: View {
    let experiment: Experiment
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var feeling: Feeling?
    @State private var why: [Tag] = []
    @State private var note = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var showCamera = false

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

                Section {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .listRowInsets(EdgeInsets())
                        Button("사진 빼기", role: .destructive) { self.photo = nil; photoItem = nil }
                    }
                    HStack {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("앨범에서", systemImage: "photo")
                        }
                        Spacer()
                        if CameraPicker.isAvailable {
                            Button { showCamera = true } label: { Label("찍기", systemImage: "camera") }
                        }
                    }
                } header: {
                    Text("엽서 사진 (선택)")
                } footer: {
                    Text("사진은 이 폰에만 저장돼요. 고른 한 장만 받고, 위치 정보는 남기지 않아요. 사진이 없으면 구역 그림 엽서가 돼요.")
                }

                Section("엽서 뒷면 한 줄 (선택)") {
                    TextField("예: 생각보다 시간이 빨리 갔다", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(experiment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("엽서 만들기") {
                        guard let feeling else { return }
                        let name = photo.flatMap { model.photos.save($0) }
                        model.record(experiment, feeling: feeling, why: feeling == .meh ? [] : why, note: note, photo: name)
                        dismiss()
                    }
                    .disabled(feeling == nil)
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        photo = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { photo = $0 }.ignoresSafeArea()
            }
        }
        .sensoryFeedback(.selection, trigger: feeling)
    }
}

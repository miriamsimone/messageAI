import SwiftUI
import PhotosUI

struct MessageInputView: View {
    @Binding var text: String
    var isSending: Bool
    var isUploadingMedia: Bool
    var onSend: () -> Void
    var onTextChange: (String) -> Void
    var onMediaSelected: (Data) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    var body: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhotoItem,
                         matching: .images,
                         photoLibrary: .shared()) {
                Group {
                    if isUploadingMedia || isLoadingPhoto {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 22))
                    }
                }
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isSending || isUploadingMedia || isLoadingPhoto)
            .onChange(of: selectedPhotoItem) { newValue in
                guard let newValue else { return }
                Task {
                    await loadImage(from: newValue)
                }
            }

            TextField("Message", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    onTextChange(newValue)
                }
            ), axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

            Button(action: onSend) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || isUploadingMedia)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func loadImage(from item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer {
            Task { @MainActor in
                isLoadingPhoto = false
                selectedPhotoItem = nil
            }
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    onMediaSelected(data)
                }
            }
        } catch {
            // Ignore transfer failures; a later retry can succeed.
        }
    }
}

#Preview {
    MessageInputView(text: .constant("Hello"),
                     isSending: false,
                     isUploadingMedia: false,
                     onSend: {},
                     onTextChange: { _ in },
                     onMediaSelected: { _ in })
}

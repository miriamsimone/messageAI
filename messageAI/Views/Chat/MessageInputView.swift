import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $text, axis: .vertical)
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
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

#Preview {
    MessageInputView(text: .constant("Hello"), isSending: false) {}
}


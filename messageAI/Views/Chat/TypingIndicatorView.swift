import SwiftUI

struct TypingIndicatorView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    TypingIndicatorView(text: "Typing...")
}

import SwiftUI

struct ConversationRowView: View {
    let conversation: ConversationSummary

    var body: some View {
        HStack(spacing: 12) {
            avatar
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                if let preview = conversation.lastMessagePreview {
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let timestamp = conversation.lastMessageAt {
                Text(timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var avatar: some View {
        Group {
            if conversation.isGroup, let url = conversation.groupAvatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                Image(systemName: conversation.isGroup ? "person.3.fill" : "person.fill")
                    .foregroundStyle(.secondary)
            )
    }
}

#Preview {
    let sample = ConversationSummary(id: "1",
                                     title: "General",
                                     lastMessagePreview: "Last message preview text",
                                     lastMessageAt: Date(),
                                     participantIDs: [],
                                     participantDetails: [:],
                                     isGroup: true,
                                     groupAvatarURL: nil)
    ConversationRowView(conversation: sample)
        .padding()
        .previewLayout(.sizeThatFits)
}

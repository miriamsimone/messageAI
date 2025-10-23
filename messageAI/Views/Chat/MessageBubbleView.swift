import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessageItem
    let isCurrentUser: Bool
    let senderName: String?
    let senderAvatarURL: URL?
    let isGroupConversation: Bool

    private let maxImageWidth: CGFloat = 240

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 40)
                contentStack(alignment: .trailing)
            } else {
                if isGroupConversation {
                    avatarView
                }
                contentStack(alignment: .leading)
                Spacer(minLength: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func contentStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            if isGroupConversation && !isCurrentUser, let senderName, !senderName.isEmpty {
                Text(senderName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            messageBody

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var messageBody: some View {
        switch message.type {
        case .text:
            Text(message.content)
                .padding(12)
                .background(isCurrentUser ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isCurrentUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        case .image:
            imageBody
        }
    }

    @ViewBuilder
    private var imageBody: some View {
        Group {
            if let url = message.mediaURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        failurePlaceholder
                    @unknown default:
                        failurePlaceholder
                    }
                }
                .frame(maxWidth: maxImageWidth, maxHeight: maxImageWidth * 1.2)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isCurrentUser ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
            } else {
                loadingPlaceholder
                    .frame(width: maxImageWidth * 0.75, height: maxImageWidth * 0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                ProgressView()
                    .progressViewStyle(.circular)
            )
    }

    private var failurePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            )
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let url = senderAvatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Circle().fill(Color(.secondarySystemBackground))
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.secondary)
                            )
                    @unknown default:
                        Circle().fill(Color(.secondarySystemBackground))
                    }
                }
            } else {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}

#Preview {
    let sample = ChatMessageItem(id: "1",
                                 conversationID: "c1",
                                 senderID: "userA",
                                 content: "Hello there!",
                                 type: .text,
                                 mediaURL: nil,
                                 timestamp: Date(),
                                 deliveryStatus: .sent,
                                 readBy: [],
                                 localID: nil)
    MessageBubbleView(message: sample,
                      isCurrentUser: true,
                      senderName: "Alex",
                      senderAvatarURL: nil,
                      isGroupConversation: false)
        .previewLayout(.sizeThatFits)

    let imageSample = ChatMessageItem(id: "2",
                                      conversationID: "c1",
                                      senderID: "userB",
                                      content: "Photo",
                                      type: .image,
                                      mediaURL: URL(string: "https://example.com/image.jpg"),
                                      timestamp: Date(),
                                      deliveryStatus: .sent,
                                      readBy: [],
                                      localID: nil)
    MessageBubbleView(message: imageSample,
                      isCurrentUser: false,
                      senderName: "Jordan",
                      senderAvatarURL: nil,
                      isGroupConversation: true)
        .previewLayout(.sizeThatFits)
}

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessageItem
    let isCurrentUser: Bool

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            Text(message.content)
                .padding(12)
                .background(isCurrentUser ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isCurrentUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
    MessageBubbleView(message: sample, isCurrentUser: true)
}


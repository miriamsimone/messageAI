import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message,
                                              isCurrentUser: message.senderID == viewModel.currentUserID)
                                .id(message.id)
                        }
                    }
                    .padding(.top, 16)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            MessageInputView(text: $viewModel.inputText,
                             isSending: viewModel.isSending) {
                viewModel.sendTextMessage()
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = viewModel.messages.last {
            withAnimation(.easeInOut) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}


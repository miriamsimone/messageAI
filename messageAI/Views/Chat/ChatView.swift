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
                                              isCurrentUser: message.senderID == viewModel.currentUserID,
                                              senderName: viewModel.displayName(for: message.senderID),
                                              senderAvatarURL: viewModel.avatarURL(for: message.senderID),
                                              isGroupConversation: viewModel.isGroupConversation)
                                .id(message.id)
                        }
                    }
                    .padding(.top, 16)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(proxy: proxy, animated: false)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
                .onChange(of: viewModel.messages.last?.id) { _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }

            if let typingText = viewModel.typingIndicatorText {
                TypingIndicatorView(text: typingText)
                    .transition(.opacity)
                    .padding(.vertical, 4)
            }

            Divider()

            MessageInputView(text: $viewModel.inputText,
                             isSending: viewModel.isSending,
                             isUploadingMedia: viewModel.isUploadingMedia,
                             onSend: {
                                 viewModel.sendTextMessage()
                             },
                             onTextChange: { viewModel.handleInputChange($0) },
                             onMediaSelected: { data in
                                 viewModel.sendImageMessage(with: data)
                             })
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.conversationTitle)
                        .font(.headline)
                    if !viewModel.presenceStatusText.isEmpty {
                        Text(viewModel.presenceStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @State private var scrollProxy: ScrollViewProxy?

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        scrollProxy = proxy
        if let last = viewModel.messages.last {
            withAnimation(animated ? .easeInOut : nil) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

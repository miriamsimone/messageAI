import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ConversationListViewModel
    private let currentUserID: String
    private let presenceService: PresenceService?
    @State private var navigationPath: [ConversationSummary] = []
    @State private var isPresentingNewConversation = false

    init(viewModel: ConversationListViewModel,
         currentUserID: String,
         presenceService: PresenceService?) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.currentUserID = currentUserID
        self.presenceService = presenceService
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(value: conversation) {
                        ConversationRowView(conversation: conversation)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isPresentingNewConversation = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Conversation")
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .navigationDestination(for: ConversationSummary.self) { conversation in
                chatDestination(for: conversation)
            }
        }
        .sheet(isPresented: $isPresentingNewConversation) {
            NewConversationView(ownerUserID: currentUserID,
                                isProcessing: viewModel.isCreatingConversation) { contact in
                handleContactSelection(contact)
            }
        }
        .overlay {
            if viewModel.isCreatingConversation {
                ProgressView("Starting chat…")
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 8)
            }
        }
    }

    @ViewBuilder
    private func chatDestination(for conversation: ConversationSummary) -> some View {
        ChatView(
            viewModel: ChatViewModel(conversationID: conversation.id,
                                     currentUserID: currentUserID,
                                     messageService: FirestoreMessageService(currentUserID: currentUserID),
                                     presenceService: presenceService,
                                     participants: conversation.participantIDs,
                                     conversationTitle: conversation.title,
                                     modelContext: modelContext)
        )
    }

    private func handleContactSelection(_ contact: Contact) {
        Task {
            let input = await MainActor.run {
                ConversationCreationInput(userID: contact.contactUserID,
                                          displayName: contact.displayName,
                                          username: contact.username,
                                          profilePictureURL: contact.profilePictureURL)
            }
            if let summary = await viewModel.createConversation(with: input) {
                await MainActor.run {
                    isPresentingNewConversation = false
                    navigationPath = [summary]
                }
            }
        }
    }
}

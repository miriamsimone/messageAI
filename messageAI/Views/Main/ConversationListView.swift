import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ConversationListViewModel
    private let currentUserID: String
    private let presenceService: PresenceService?
    @Binding private var pendingRoute: NotificationRoute?
    @State private var navigationPath: [ConversationSummary] = []
    @State private var isPresentingNewConversation = false
    @State private var isPresentingNewGroup = false
    @State private var activeRoute: NotificationRoute?
    @State private var hasRequestedRefreshForActiveRoute = false

    init(viewModel: ConversationListViewModel,
         currentUserID: String,
         presenceService: PresenceService?,
         pendingRoute: Binding<NotificationRoute?> = .constant(nil)) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.currentUserID = currentUserID
        self.presenceService = presenceService
        _pendingRoute = pendingRoute
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
                    Menu {
                        Button {
                            isPresentingNewConversation = true
                        } label: {
                            Label("New Chat", systemImage: "bubble.left.and.bubble.right")
                        }

                        Button {
                            isPresentingNewGroup = true
                        } label: {
                            Label("New Group", systemImage: "person.3")
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Compose")
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
        .sheet(isPresented: $isPresentingNewGroup) {
            CreateGroupView(ownerUserID: currentUserID,
                            isProcessing: viewModel.isCreatingConversation) { name, contacts in
                handleGroupCreation(name: name, contacts: contacts)
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
        .onAppear {
            syncRouteIfNeeded()
        }
        .onChange(of: pendingRoute) { _ in
            syncRouteIfNeeded()
        }
        .onChange(of: viewModel.conversations) { _ in
            fulfillRouteIfPossible()
        }
    }

    @ViewBuilder
    private func chatDestination(for conversation: ConversationSummary) -> some View {
        ChatView(
            viewModel: ChatViewModel(conversationID: conversation.id,
                                     currentUserID: currentUserID,
                                     messageService: FirestoreMessageService(currentUserID: currentUserID),
                                     storageService: FirebaseStorageService(currentUserID: currentUserID),
                                     presenceService: presenceService,
                                     participantIDs: conversation.participantIDs,
                                     participantDetails: conversation.participantDetails,
                                     isGroupConversation: conversation.isGroup,
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

    private func handleGroupCreation(name: String, contacts: [Contact]) {
        Task {
            let inputs = await MainActor.run {
                contacts.map { contact in
                    ConversationCreationInput(userID: contact.contactUserID,
                                              displayName: contact.displayName,
                                              username: contact.username,
                                              profilePictureURL: contact.profilePictureURL)
                }
            }

            if let summary = await viewModel.createGroupConversation(name: name,
                                                                     participants: inputs) {
                await MainActor.run {
                    isPresentingNewGroup = false
                    navigationPath = [summary]
                }
            }
        }
    }

    private func syncRouteIfNeeded() {
        guard let pendingRoute else { return }
        activeRoute = pendingRoute
        hasRequestedRefreshForActiveRoute = false
        fulfillRouteIfPossible()
    }

    private func fulfillRouteIfPossible() {
        guard let route = activeRoute else { return }

        if let target = viewModel.conversations.first(where: { $0.id == route.conversationID }) {
            navigationPath = [target]
            activeRoute = nil
            pendingRoute = nil
            hasRequestedRefreshForActiveRoute = false
        } else {
            guard !hasRequestedRefreshForActiveRoute else { return }
            hasRequestedRefreshForActiveRoute = true
            viewModel.refresh()
        }
    }
}

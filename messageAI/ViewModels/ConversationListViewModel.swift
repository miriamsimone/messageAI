import Foundation
import Combine
import SwiftData

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published private(set) var conversations: [ConversationSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isCreatingConversation = false
    @Published var errorMessage: String?

    private let conversationService: ConversationService
    private let modelContext: ModelContext
    private let currentUserID: String
    private var listenerToken: ConversationListeningToken?

    init(conversationService: ConversationService,
         modelContext: ModelContext,
         currentUserID: String) {
        self.conversationService = conversationService
        self.modelContext = modelContext
        self.currentUserID = currentUserID
        loadLocalConversations()
        startListening()
    }

    deinit {
        listenerToken?.stop()
    }

    func refresh() {
        startListening()
    }

    func createConversation(with participant: ConversationCreationInput) async -> ConversationSummary? {
        guard !isCreatingConversation else { return nil }
        isCreatingConversation = true
        errorMessage = nil
        defer { isCreatingConversation = false }

        do {
            let summary = try await conversationService.createOneOnOneConversation(with: participant)
            try upsertLocalConversation(with: summary)
            loadLocalConversations()
            return summary
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func createGroupConversation(name: String,
                                 participants: [ConversationCreationInput]) async -> ConversationSummary? {
        guard !isCreatingConversation else { return nil }
        isCreatingConversation = true
        errorMessage = nil
        defer { isCreatingConversation = false }

        do {
            let summary = try await conversationService.createGroupConversation(name: name,
                                                                                participants: participants,
                                                                                groupAvatarURL: nil)
            try upsertLocalConversation(with: summary)
            loadLocalConversations()
            return summary
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func loadLocalConversations() {
        let descriptor = FetchDescriptor<Conversation>()

        if let stored = try? modelContext.fetch(descriptor) {
            conversations = stored
                .filter { $0.participantIDs.contains(currentUserID) }
                .map { summary(from: $0) }
                .sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
        }
    }

    private func startListening() {
        listenerToken?.stop()

        listenerToken = conversationService.listenForConversations { [weak self] summaries in
            guard let self else { return }
            Task { @MainActor in
                self.conversations = summaries
                do {
                    try self.syncLocalConversations(with: summaries)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        } onError: { [weak self] error in
            Task { @MainActor in
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    private func syncLocalConversations(with remote: [ConversationSummary]) throws {
        let descriptor = FetchDescriptor<Conversation>()

        let stored = try modelContext.fetch(descriptor)
            .filter { $0.participantIDs.contains(currentUserID) }
        var storedByID = Dictionary(uniqueKeysWithValues: stored.map { ($0.remoteID, $0) })
        let remoteIDs = Set(remote.map(\.id))

        for summary in remote {
            if let existing = storedByID.removeValue(forKey: summary.id) {
                existing.lastMessagePreview = summary.lastMessagePreview
                existing.lastMessageTimestamp = summary.lastMessageAt
                existing.participantIDs = summary.participantIDs
                existing.groupName = summary.isGroup ? summary.title : nil
                existing.groupAvatarURL = summary.groupAvatarURL
                existing.type = summary.isGroup ? .group : .oneOnOne
                updateDisplayNames(for: existing, with: summary)
            } else {
                let conversation = Conversation(remoteID: summary.id,
                                                type: summary.isGroup ? .group : .oneOnOne,
                                                participantIDs: summary.participantIDs,
                                                groupName: summary.isGroup ? summary.title : nil,
                                                groupAvatarURL: summary.groupAvatarURL,
                                                lastMessagePreview: summary.lastMessagePreview,
                                                lastMessageTimestamp: summary.lastMessageAt,
                                                createdAt: summary.lastMessageAt ?? Date(),
                                                createdByUserID: currentUserID,
                                                participantDisplayNames: displayNameDictionary(from: summary))
                modelContext.insert(conversation)
            }
        }

        for obsolete in storedByID.values where !remoteIDs.contains(obsolete.remoteID) {
            modelContext.delete(obsolete)
        }

        try modelContext.save()
    }

    private func upsertLocalConversation(with summary: ConversationSummary) throws {
        let remoteID = summary.id
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.remoteID == remoteID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.lastMessagePreview = summary.lastMessagePreview
            existing.lastMessageTimestamp = summary.lastMessageAt
            existing.participantIDs = summary.participantIDs
            existing.groupName = summary.isGroup ? summary.title : nil
            existing.groupAvatarURL = summary.groupAvatarURL
            existing.type = summary.isGroup ? .group : .oneOnOne
            updateDisplayNames(for: existing, with: summary)
        } else {
            let conversation = Conversation(remoteID: summary.id,
                                            type: summary.isGroup ? .group : .oneOnOne,
                                            participantIDs: summary.participantIDs,
                                            groupName: summary.isGroup ? summary.title : nil,
                                            groupAvatarURL: summary.groupAvatarURL,
                                            lastMessagePreview: summary.lastMessagePreview,
                                            lastMessageTimestamp: summary.lastMessageAt,
                                            createdAt: summary.lastMessageAt ?? Date(),
                                            createdByUserID: currentUserID,
                                            participantDisplayNames: displayNameDictionary(from: summary))
            modelContext.insert(conversation)
        }

        try modelContext.save()
    }

    private func summary(from conversation: Conversation) -> ConversationSummary {
        let title: String = {
            if conversation.type == .group {
                return conversation.groupName ?? "Group"
            }
            if let otherID = conversation.participantIDs.first(where: { $0 != currentUserID }),
               let name = conversation.participantDisplayNames[otherID], !name.isEmpty {
                return name
            }
            return conversation.lastMessagePreview ?? "Conversation"
        }()

        let participantDetails = Dictionary(uniqueKeysWithValues: conversation.participantIDs.map { userID in
            (userID, ConversationParticipant(id: userID,
                                             displayName: conversation.participantDisplayNames[userID],
                                             username: nil,
                                             profilePictureURL: nil))
        })

        return ConversationSummary(id: conversation.remoteID,
                                   title: title,
                                   lastMessagePreview: conversation.lastMessagePreview,
                                   lastMessageAt: conversation.lastMessageTimestamp,
                                   participantIDs: conversation.participantIDs,
                                   participantDetails: participantDetails,
                                   isGroup: conversation.type == .group,
                                   groupAvatarURL: conversation.groupAvatarURL)
    }

    private func displayNameDictionary(from summary: ConversationSummary) -> [String: String] {
        summary.participantDetails.reduce(into: [:]) { result, element in
            if let name = element.value.displayName {
                result[element.key] = name
            }
        }
    }

    private func updateDisplayNames(for conversation: Conversation,
                                    with summary: ConversationSummary) {
        var merged = conversation.participantDisplayNames
        for (userID, participant) in summary.participantDetails {
            if let name = participant.displayName {
                merged[userID] = name
            }
        }
        conversation.participantDisplayNames = merged
    }
}

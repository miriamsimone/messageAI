import Foundation
import Combine
import SwiftData

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessageItem] = []
    @Published var inputText: String = ""
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    let conversationID: String
    let currentUserID: String

    private let messageService: MessageService
    private let modelContext: ModelContext
    private var listenerToken: MessageListeningToken?

    init(conversationID: String,
         currentUserID: String,
         messageService: MessageService,
         modelContext: ModelContext) {
        self.conversationID = conversationID
        self.currentUserID = currentUserID
        self.messageService = messageService
        self.modelContext = modelContext

        loadLocalMessages()
        startListening()
    }

    deinit {
        listenerToken?.stop()
    }

    func sendTextMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let localID = UUID().uuidString
        inputText = ""

        do {
            try insertLocalMessage(localID: localID, content: trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }

        Task {
            await sendMessage(content: trimmed, localID: localID)
        }
    }

    private func loadLocalMessages() {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.conversation?.remoteID == conversationID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        if let stored = try? modelContext.fetch(descriptor) {
            messages = stored.map {
                ChatMessageItem(id: $0.remoteID,
                                conversationID: conversationID,
                                senderID: $0.senderUserID,
                                content: $0.content,
                                type: $0.contentType,
                                mediaURL: $0.mediaURL,
                                timestamp: $0.timestamp,
                                deliveryStatus: $0.deliveryStatus,
                                readBy: $0.readByUserIDs,
                                localID: $0.localID)
            }
        }
    }

    private func startListening() {
        listenerToken?.stop()
        listenerToken = messageService.listenForMessages(in: conversationID) { [weak self] items in
            guard let self else { return }
            Task { @MainActor in
                do {
                    try self.syncLocalMessages(with: items)
                    self.loadLocalMessages()
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

    private func insertLocalMessage(localID: String, content: String) throws {
        guard let conversation = try fetchConversation() else { return }
        let message = Message(remoteID: localID,
                              localID: localID,
                              conversation: conversation,
                              senderUserID: currentUserID,
                              content: content,
                              contentType: .text,
                              mediaURL: nil,
                              timestamp: Date(),
                              deliveryStatus: .sending,
                              readByUserIDs: [currentUserID])
        modelContext.insert(message)
        try modelContext.save()
        loadLocalMessages()
    }

    private func sendMessage(content: String, localID: String) async {
        guard !isSending else { return }
        isSending = true
        do {
            let remote = try await messageService.sendMessage(to: conversationID,
                                                              content: content,
                                                              type: .text,
                                                              localID: localID,
                                                              metadata: nil)
            try updateLocalMessage(localID: localID, with: remote)
        } catch {
            errorMessage = error.localizedDescription
            try? markMessageFailed(localID: localID)
        }
        isSending = false
    }

    private func updateLocalMessage(localID: String, with remote: ChatMessageItem) throws {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.localID == localID && $0.conversation?.remoteID == conversationID }
        )
        guard let message = try modelContext.fetch(descriptor).first else {
            return
        }

        message.remoteID = remote.id
        message.timestamp = remote.timestamp
        message.deliveryStatus = remote.deliveryStatus
        message.readByUserIDs = remote.readBy
        try modelContext.save()
        loadLocalMessages()
    }

    private func markMessageFailed(localID: String) throws {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.localID == localID && $0.conversation?.remoteID == conversationID }
        )
        if let message = try modelContext.fetch(descriptor).first {
            message.deliveryStatus = .sending
            try modelContext.save()
            loadLocalMessages()
        }
    }

    private func syncLocalMessages(with remote: [ChatMessageItem]) throws {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.conversation?.remoteID == conversationID }
        )
        let stored = try modelContext.fetch(descriptor)

        var storedByRemoteID = Dictionary(uniqueKeysWithValues: stored.map { ($0.remoteID, $0) })
        let storedByLocalID = Dictionary(grouping: stored.filter { $0.localID != nil }, by: { $0.localID! })

        let remoteIDs = Set(remote.map(\.id))

        for item in remote {
            if let existing = storedByRemoteID.removeValue(forKey: item.id) {
                existing.content = item.content
                existing.timestamp = item.timestamp
                existing.deliveryStatus = item.deliveryStatus
                existing.readByUserIDs = item.readBy
                existing.mediaURL = item.mediaURL
                existing.senderUserID = item.senderID
            } else if let localID = item.localID,
                      let localExisting = storedByLocalID[localID]?.first {
                storedByRemoteID[localExisting.remoteID] = nil
                localExisting.remoteID = item.id
                localExisting.content = item.content
                localExisting.timestamp = item.timestamp
                localExisting.deliveryStatus = item.deliveryStatus
                localExisting.readByUserIDs = item.readBy
                localExisting.mediaURL = item.mediaURL
                localExisting.senderUserID = item.senderID
            } else {
                guard let conversation = try fetchConversation() else { continue }
                let newMessage = Message(remoteID: item.id,
                                         localID: item.localID,
                                         conversation: conversation,
                                         senderUserID: item.senderID,
                                         content: item.content,
                                         contentType: item.type,
                                         mediaURL: item.mediaURL,
                                         timestamp: item.timestamp,
                                         deliveryStatus: item.deliveryStatus,
                                         readByUserIDs: item.readBy)
                modelContext.insert(newMessage)
            }
        }

        for orphan in storedByRemoteID.values where !remoteIDs.contains(orphan.remoteID) {
            // Keep optimistic messages (likely sending). Don't delete for now.
            continue
        }

        try modelContext.save()
    }

    private func fetchConversation() throws -> Conversation? {
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.remoteID == conversationID }
        )
        return try modelContext.fetch(descriptor).first
    }
}

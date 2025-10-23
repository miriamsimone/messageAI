import Foundation
import Combine
import SwiftData

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessageItem] = []
    @Published var inputText: String = ""
    @Published private(set) var isSending = false
    @Published var errorMessage: String?
    @Published private(set) var presenceStates: [UserPresenceState] = []
    @Published private(set) var typingStatuses: [TypingStatus] = []

    let conversationID: String
    let currentUserID: String
    let conversationTitle: String

    private let messageService: MessageService
    private let presenceService: PresenceService?
    private let participants: [String]
    private let modelContext: ModelContext
    private var listenerToken: MessageListeningToken?
    private var presenceListener: PresenceListeningToken?
    private var typingListener: PresenceListeningToken?
    private var typingTask: Task<Void, Never>?
    private var isTypingActive = false

    init(conversationID: String,
         currentUserID: String,
         messageService: MessageService,
         presenceService: PresenceService?,
         participants: [String],
         conversationTitle: String,
         modelContext: ModelContext) {
        self.conversationID = conversationID
        self.currentUserID = currentUserID
        self.messageService = messageService
        self.presenceService = presenceService
        self.participants = participants
        self.conversationTitle = conversationTitle
        self.modelContext = modelContext

        loadLocalMessages()
        startListening()
        observePresence()
        observeTyping()
    }

    deinit {
        listenerToken?.stop()
        presenceListener?.stop()
        typingListener?.stop()
        typingTask?.cancel()
        Task { [presenceService, conversationID] in
            try? await presenceService?.setTypingState(conversationID: conversationID, isTyping: false)
        }
    }

    func sendTextMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let localID = UUID().uuidString
        inputText = ""
        typingTask?.cancel()
        if isTypingActive {
            Task { [presenceService, conversationID] in
                try? await presenceService?.setTypingState(conversationID: conversationID, isTyping: false)
            }
            isTypingActive = false
        }

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

        if isTypingActive {
            Task { [presenceService, conversationID] in
                try? await presenceService?.setTypingState(conversationID: conversationID, isTyping: false)
            }
            isTypingActive = false
        }

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

    func handleInputChange(_ text: String) {
        typingTask?.cancel()
        guard let presenceService else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if isTypingActive {
                typingTask = Task { [conversationID, weak self] in
                    try? await presenceService.setTypingState(conversationID: conversationID, isTyping: false)
                    await MainActor.run { self?.isTypingActive = false }
                }
            }
            return
        }

        typingTask = Task { [conversationID, weak self] in
            guard let self else { return }
            if !self.isTypingActive {
                try? await presenceService.setTypingState(conversationID: conversationID, isTyping: true)
                await MainActor.run { self.isTypingActive = true }
            }

            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if Task.isCancelled { return }
            try? await presenceService.setTypingState(conversationID: conversationID, isTyping: false)
            await MainActor.run { self.isTypingActive = false }
        }
    }

    var presenceStatusText: String {
        let others = participants.filter { $0 != currentUserID }
        guard !others.isEmpty else { return "" }

        let states = presenceStates.filter { others.contains($0.userID) }
        if others.count == 1, let userID = others.first,
           let state = states.first(where: { $0.userID == userID }) {
            if state.isOnline { return "Online" }
            if let lastSeen = state.lastSeen {
                return "Last seen " + Self.relativeFormatter.localizedString(for: lastSeen, relativeTo: Date())
            }
            return "Offline"
        }

        let onlineCount = states.filter { $0.isOnline }.count
        if onlineCount == 0 { return "No one online" }
        if onlineCount == states.count { return "All online" }
        return "\(onlineCount) online"
    }

    var typingIndicatorText: String? {
        let active = typingStatuses.filter { $0.isTyping }
        guard !active.isEmpty else { return nil }
        if participants.count <= 2 {
            return "Typing..."
        }
        return "Multiple people typing..."
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

    private func observePresence() {
        guard let presenceService else { return }
        let targets = participants.filter { $0 != currentUserID }
        guard !targets.isEmpty else { return }

        presenceListener?.stop()
        presenceListener = presenceService.listenForPresence(userIDs: targets) { [weak self] states in
            Task { @MainActor in
                self?.presenceStates = states
            }
        } onError: { [weak self] error in
            Task { @MainActor in
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    private func observeTyping() {
        guard let presenceService else { return }
        typingListener?.stop()
        typingListener = presenceService.listenForTyping(conversationID: conversationID) { [weak self] statuses in
            Task { @MainActor in
                self?.typingStatuses = statuses
            }
        } onError: { [weak self] error in
            Task { @MainActor in
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

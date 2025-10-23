import Foundation

/// Represents a user's typing state in a conversation
/// Note: This is NOT persisted locally - only used for Firestore real-time state
struct TypingIndicator: Identifiable, Sendable {
    var id: UUID
    var conversationID: String
    var userID: String
    var isTyping: Bool
    var updatedAt: Date

    init(id: UUID = UUID(),
         conversationID: String,
         userID: String,
         isTyping: Bool,
         updatedAt: Date = .now) {
        self.id = id
        self.conversationID = conversationID
        self.userID = userID
        self.isTyping = isTyping
        self.updatedAt = updatedAt
    }
}


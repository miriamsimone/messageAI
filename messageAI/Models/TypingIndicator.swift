import Foundation
import SwiftData

@Model
final class TypingIndicator {
    @Attribute(.unique) var id: UUID
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


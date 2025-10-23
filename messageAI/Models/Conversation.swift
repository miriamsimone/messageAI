import Foundation
import SwiftData

enum ConversationType: String, Codable, Sendable {
    case oneOnOne
    case group
}

@Model
final class Conversation {
    @Attribute(.unique) var remoteID: String
    var type: ConversationType
    var participantIDs: [String]
    var groupName: String?
    var groupAvatarURL: URL?
    var lastMessagePreview: String?
    var lastMessageTimestamp: Date?
    var createdAt: Date
    var createdByUserID: String
    var participantDisplayNames: [String: String]

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]

    init(remoteID: String,
         type: ConversationType,
         participantIDs: [String],
         groupName: String? = nil,
         groupAvatarURL: URL? = nil,
         lastMessagePreview: String? = nil,
         lastMessageTimestamp: Date? = nil,
         createdAt: Date = .now,
         createdByUserID: String,
         participantDisplayNames: [String: String] = [:]) {
        self.remoteID = remoteID
        self.type = type
        self.participantIDs = participantIDs
        self.groupName = groupName
        self.groupAvatarURL = groupAvatarURL
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageTimestamp = lastMessageTimestamp
        self.createdAt = createdAt
        self.createdByUserID = createdByUserID
        self.participantDisplayNames = participantDisplayNames
        self.messages = []
    }
}

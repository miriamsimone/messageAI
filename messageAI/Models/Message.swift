import Foundation
import SwiftData

enum MessageContentType: String, Codable, Sendable {
    case text
    case image
}

enum MessageDeliveryStatus: String, Codable, Sendable {
    case sending
    case sent
    case delivered
    case read
}

@Model
final class Message {
    @Attribute(.unique) var remoteID: String
    var localID: String?

    @Relationship var conversation: Conversation?

    var senderUserID: String
    var content: String
    var contentType: MessageContentType
    var mediaURL: URL?
    var timestamp: Date
    var deliveryStatus: MessageDeliveryStatus
    var readByUserIDs: [String]

    init(remoteID: String,
         localID: String? = nil,
         conversation: Conversation? = nil,
         senderUserID: String,
         content: String,
         contentType: MessageContentType = .text,
         mediaURL: URL? = nil,
         timestamp: Date = .now,
         deliveryStatus: MessageDeliveryStatus = .sending,
         readByUserIDs: [String] = []) {
        self.remoteID = remoteID
        self.localID = localID
        self.conversation = conversation
        self.senderUserID = senderUserID
        self.content = content
        self.contentType = contentType
        self.mediaURL = mediaURL
        self.timestamp = timestamp
        self.deliveryStatus = deliveryStatus
        self.readByUserIDs = readByUserIDs
    }
}


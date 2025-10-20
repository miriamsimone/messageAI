import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var remoteID: String
    var displayName: String
    var username: String
    var email: String
    var profilePictureURL: URL?
    var isOnline: Bool
    var lastSeen: Date?
    var fcmToken: String?
    var contacts: [String]
    var createdAt: Date

    init(remoteID: String,
         displayName: String,
         username: String,
         email: String,
         profilePictureURL: URL? = nil,
         isOnline: Bool = false,
         lastSeen: Date? = nil,
         fcmToken: String? = nil,
         contacts: [String] = [],
         createdAt: Date = .now) {
        self.remoteID = remoteID
        self.displayName = displayName
        self.username = username.lowercased()
        self.email = email.lowercased()
        self.profilePictureURL = profilePictureURL
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.fcmToken = fcmToken
        self.contacts = contacts
        self.createdAt = createdAt
    }
}


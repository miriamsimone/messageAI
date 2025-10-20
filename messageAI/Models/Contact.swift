import Foundation
import SwiftData

@Model
final class Contact {
    @Attribute(.unique) var remoteID: String
    var ownerUserID: String
    var contactUserID: String
    var displayName: String
    var username: String
    var profilePictureURL: URL?
    var createdAt: Date

    init(remoteID: String,
         ownerUserID: String,
         contactUserID: String,
         displayName: String,
         username: String,
         profilePictureURL: URL? = nil,
         createdAt: Date = .now) {
        self.remoteID = remoteID
        self.ownerUserID = ownerUserID
        self.contactUserID = contactUserID
        self.displayName = displayName
        self.username = username.lowercased()
        self.profilePictureURL = profilePictureURL
        self.createdAt = createdAt
    }
}


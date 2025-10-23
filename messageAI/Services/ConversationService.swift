import Foundation

struct ConversationSummary: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let lastMessagePreview: String?
    let lastMessageAt: Date?
    let participantIDs: [String]
    let isGroup: Bool
    let groupAvatarURL: URL?
}

struct ConversationCreationInput: Sendable {
    let userID: String
    let displayName: String
    let username: String
    let profilePictureURL: URL?
}

protocol ConversationListeningToken {
    func stop()
}

protocol ConversationService {
    func listenForConversations(onChange: @escaping ([ConversationSummary]) -> Void,
                                onError: @escaping (Error) -> Void) -> ConversationListeningToken
    func createOneOnOneConversation(with participant: ConversationCreationInput) async throws -> ConversationSummary
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

final class FirestoreConversationService: ConversationService {
    private let db = Firestore.firestore()
    private let currentUserID: String
    private let currentUserDisplayName: String
    private let currentUsername: String?

    init(currentUserID: String,
         currentUserDisplayName: String,
         currentUsername: String?) {
        self.currentUserID = currentUserID
        self.currentUserDisplayName = currentUserDisplayName
        self.currentUsername = currentUsername?.nilIfEmpty
    }

    func listenForConversations(onChange: @escaping ([ConversationSummary]) -> Void,
                                onError: @escaping (Error) -> Void) -> ConversationListeningToken {
        let query = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserID)
            .order(by: "lastMessageTimestamp", descending: true)

        let registration = query.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            guard let documents = snapshot?.documents else {
                onChange([])
                return
            }

            let summaries: [ConversationSummary] = documents.compactMap { doc in
                let data = doc.data()
                guard let participants = data["participants"] as? [String],
                      let type = data["type"] as? String else {
                    return nil
                }

                let lastMessage = data["lastMessage"] as? String
                let timestamp = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue()
                let isGroup = type == "group"
                let participantDisplayNames = data["participantDisplayNames"] as? [String: String]
                let participantAvatarURLs = data["participantProfilePictureURLs"] as? [String: String]
                let conversationAvatarURL: URL? = {
                    if isGroup {
                        if let urlString = data["groupAvatarURL"] as? String {
                            return URL(string: urlString)
                        }
                        return nil
                    } else {
                        guard let otherID = participants.first(where: { $0 != self.currentUserID }),
                              let urlString = participantAvatarURLs?[otherID] else {
                            return nil
                        }
                        return URL(string: urlString)
                    }
                }()

                let title: String = {
                    if isGroup {
                        return (data["groupName"] as? String) ?? "Group"
                    } else {
                        if let otherID = participants.first(where: { $0 != self.currentUserID }),
                           let name = participantDisplayNames?[otherID]?.nilIfEmpty {
                            return name
                        }
                        if let fallback = data["displayName"] as? String, !fallback.isEmpty {
                            return fallback
                        }
                        return "Conversation"
                    }
                }()

                return ConversationSummary(id: doc.documentID,
                                           title: title,
                                           lastMessagePreview: lastMessage,
                                           lastMessageAt: timestamp,
                                           participantIDs: participants,
                                           isGroup: isGroup,
                                           groupAvatarURL: conversationAvatarURL)
            }

            onChange(summaries)
        }

        return FirestoreListenerToken(registration: registration)
    }

    func createOneOnOneConversation(with participant: ConversationCreationInput) async throws -> ConversationSummary {
        let participantIDs = [currentUserID, participant.userID].sorted()
        let conversationID = "dm_\(participantIDs.joined(separator: "_"))"
        let docRef = db.collection("conversations").document(conversationID)

        let snapshot = try await docRef.getDocument()
        let now = Timestamp(date: Date())

        var data: [String: Any] = [
            "type": "oneOnOne",
            "participants": participantIDs,
            "participantDisplayNames": [
                currentUserID: currentUserDisplayName,
                participant.userID: participant.displayName
            ],
            "participantUsernames": compactDictionary([
                currentUserID: currentUsername,
                participant.userID: participant.username.nilIfEmpty
            ]),
            "participantProfilePictureURLs": compactDictionary([
                currentUserID: nil,
                participant.userID: participant.profilePictureURL?.absoluteString
            ]),
            "displayName": participant.displayName,
            "createdBy": currentUserID
        ]

        if snapshot.exists {
            try await docRef.setData(data, merge: true)
        } else {
            data["createdAt"] = now
            try await docRef.setData(data)
        }

        return ConversationSummary(id: conversationID,
                                   title: participant.displayName,
                                   lastMessagePreview: nil,
                                   lastMessageAt: nil,
                                   participantIDs: participantIDs,
                                   isGroup: false,
                                   groupAvatarURL: participant.profilePictureURL)
    }

    private func compactDictionary(_ values: [String: String?]) -> [String: String] {
        values.compactMapValues { $0?.nilIfEmpty }
    }
}

final class FirestoreListenerToken: ConversationListeningToken, MessageListeningToken {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration?) {
        self.registration = registration
    }

    func stop() {
        registration?.remove()
        registration = nil
    }
}
#else
final class FirestoreConversationService: ConversationService {
    init(currentUserID: String,
         currentUserDisplayName: String,
         currentUsername: String?) {}

    func listenForConversations(onChange: @escaping ([ConversationSummary]) -> Void,
                                onError: @escaping (Error) -> Void) -> ConversationListeningToken {
        onError(UserServiceError.firebaseSDKMissing)
        return EmptyConversationListener()
    }

    func createOneOnOneConversation(with participant: ConversationCreationInput) async throws -> ConversationSummary {
        throw UserServiceError.firebaseSDKMissing
    }
}

final class EmptyConversationListener: ConversationListeningToken, MessageListeningToken {
    func stop() {}
}
#endif

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

import Foundation

struct ConversationParticipant: Equatable, Hashable, Sendable {
    let id: String
    let displayName: String?
    let username: String?
    let profilePictureURL: URL?
}

struct ConversationSummary: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let lastMessagePreview: String?
    let lastMessageAt: Date?
    let participantIDs: [String]
    let participantDetails: [String: ConversationParticipant]
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
    func createGroupConversation(name: String,
                                 participants: [ConversationCreationInput],
                                 groupAvatarURL: URL?) async throws -> ConversationSummary
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
                let participantUsernames = data["participantUsernames"] as? [String: String]
                let participantAvatarURLs = data["participantProfilePictureURLs"] as? [String: String]
                let participantDetails: [String: ConversationParticipant] = Dictionary(uniqueKeysWithValues: participants.map { userID in
                    let avatarURL = participantAvatarURLs?[userID].flatMap(URL.init(string:))
                    return (userID, ConversationParticipant(id: userID,
                                                            displayName: participantDisplayNames?[userID],
                                                            username: participantUsernames?[userID],
                                                            profilePictureURL: avatarURL))
                })
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
                                           participantDetails: participantDetails,
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

        let participantDetails: [String: ConversationParticipant] = [
            currentUserID: ConversationParticipant(id: currentUserID,
                                                   displayName: currentUserDisplayName,
                                                   username: currentUsername,
                                                   profilePictureURL: nil),
            participant.userID: ConversationParticipant(id: participant.userID,
                                                        displayName: participant.displayName,
                                                        username: participant.username,
                                                        profilePictureURL: participant.profilePictureURL)
        ]

        return ConversationSummary(id: conversationID,
                                   title: participant.displayName,
                                   lastMessagePreview: nil,
                                   lastMessageAt: nil,
                                   participantIDs: participantIDs,
                                   participantDetails: participantDetails,
                                   isGroup: false,
                                   groupAvatarURL: participant.profilePictureURL)
    }

    func createGroupConversation(name: String,
                                 participants: [ConversationCreationInput],
                                 groupAvatarURL: URL?) async throws -> ConversationSummary {
        var allParticipantIDs = Set(participants.map(\.userID))
        allParticipantIDs.insert(currentUserID)

        if allParticipantIDs.count < 3 {
            throw NSError(domain: "Conversation", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Groups require at least 3 members."
            ])
        }

        let docRef = db.collection("conversations").document()
        let now = Timestamp(date: Date())

        var participantDisplayNames: [String: String] = [
            currentUserID: currentUserDisplayName
        ]
        var participantUsernames: [String: String] = [:]
        var participantProfilePictureURLs: [String: String] = [:]

        if let currentUsername {
            participantUsernames[currentUserID] = currentUsername
        }

        for participant in participants {
            participantDisplayNames[participant.userID] = participant.displayName
            participantUsernames[participant.userID] = participant.username.nilIfEmpty
            if let urlString = participant.profilePictureURL?.absoluteString {
                participantProfilePictureURLs[participant.userID] = urlString
            }
        }

        var data: [String: Any] = [
            "type": "group",
            "groupName": name,
            "participants": Array(allParticipantIDs),
            "participantDisplayNames": participantDisplayNames,
            "participantUsernames": participantUsernames,
            "participantProfilePictureURLs": participantProfilePictureURLs,
            "createdBy": currentUserID,
            "createdAt": now
        ]

        if let groupAvatarURL {
            data["groupAvatarURL"] = groupAvatarURL.absoluteString
        }

        try await docRef.setData(data)

        let participantDetails: [String: ConversationParticipant] = Dictionary(uniqueKeysWithValues: allParticipantIDs.map { userID in
            ConversationParticipant(id: userID,
                                    displayName: participantDisplayNames[userID],
                                    username: participantUsernames[userID],
                                    profilePictureURL: participantProfilePictureURLs[userID].flatMap(URL.init(string:)))
        }.map { ($0.id, $0) })

        return ConversationSummary(id: docRef.documentID,
                                   title: name,
                                   lastMessagePreview: nil,
                                   lastMessageAt: nil,
                                   participantIDs: Array(allParticipantIDs),
                                   participantDetails: participantDetails,
                                   isGroup: true,
                                   groupAvatarURL: groupAvatarURL)
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

    func createGroupConversation(name: String,
                                 participants: [ConversationCreationInput],
                                 groupAvatarURL: URL?) async throws -> ConversationSummary {
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

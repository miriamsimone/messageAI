import Foundation

struct UserPresenceState: Identifiable, Equatable, Sendable {
    let userID: String
    let isOnline: Bool
    let lastSeen: Date?

    var id: String { userID }
}

struct TypingStatus: Identifiable, Equatable, Sendable {
    let userID: String
    let isTyping: Bool
    let updatedAt: Date?

    var id: String { userID }
}

protocol PresenceListeningToken {
    func stop()
}

protocol PresenceService: Sendable {
    func setUserOnline() async throws
    func setUserOffline() async throws

    func listenForPresence(userIDs: [String],
                           onChange: @escaping ([UserPresenceState]) -> Void,
                           onError: @escaping (Error) -> Void) -> PresenceListeningToken?

    func setTypingState(conversationID: String,
                        isTyping: Bool) async throws

    func listenForTyping(conversationID: String,
                         onChange: @escaping ([TypingStatus]) -> Void,
                         onError: @escaping (Error) -> Void) -> PresenceListeningToken?
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

final class FirestorePresenceService: PresenceService {
    private let db = Firestore.firestore()
    private let currentUserID: String
    private let presenceCollection: CollectionReference

    init(currentUserID: String) {
        self.currentUserID = currentUserID
        self.presenceCollection = db.collection("presence")
    }

    func setUserOnline() async throws {
        try await presenceDocument(for: currentUserID).setData([
            "isOnline": true,
            "lastSeen": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func setUserOffline() async throws {
        try await presenceDocument(for: currentUserID).setData([
            "isOnline": false,
            "lastSeen": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func listenForPresence(userIDs: [String],
                           onChange: @escaping ([UserPresenceState]) -> Void,
                           onError: @escaping (Error) -> Void) -> PresenceListeningToken? {
        guard !userIDs.isEmpty else { return nil }
        let chunks = stride(from: 0, to: userIDs.count, by: 10).map {
            Array(userIDs[$0..<min($0 + 10, userIDs.count)])
        }

        var registrations: [ListenerRegistration] = []
        var stateMap: [String: UserPresenceState] = [:]
        let syncQueue = DispatchQueue(label: "presence-state-\(currentUserID)")

        for chunk in chunks {
            let query = presenceCollection.whereField(FieldPath.documentID(), in: chunk)
            let registration = query.addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }

                guard let documents = snapshot?.documents else {
                    syncQueue.async {
                        for userID in chunk {
                            stateMap[userID] = UserPresenceState(userID: userID, isOnline: false, lastSeen: nil)
                        }
                        let ordered = userIDs.map { stateMap[$0] ?? UserPresenceState(userID: $0, isOnline: false, lastSeen: nil) }
                        DispatchQueue.main.async {
                            onChange(ordered)
                        }
                    }
                    return
                }

                syncQueue.async {
                    var localMap: [String: UserPresenceState] = [:]
                    for doc in documents {
                        let data = doc.data()
                        let isOnline = data["isOnline"] as? Bool ?? false
                        let lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue()
                        localMap[doc.documentID] = UserPresenceState(userID: doc.documentID,
                                                                     isOnline: isOnline,
                                                                     lastSeen: lastSeen)
                    }

                    for userID in chunk {
                        stateMap[userID] = localMap[userID] ?? UserPresenceState(userID: userID, isOnline: false, lastSeen: nil)
                    }

                    let ordered = userIDs.map { stateMap[$0] ?? UserPresenceState(userID: $0, isOnline: false, lastSeen: nil) }
                    DispatchQueue.main.async {
                        onChange(ordered)
                    }
                }
            }
            registrations.append(registration)
        }

        return FirestorePresenceListener(registrations: registrations)
    }

    func setTypingState(conversationID: String,
                        isTyping: Bool) async throws {
        let typingRef = typingDocument(conversationID: conversationID, userID: currentUserID)
        if isTyping {
            try await typingRef.setData([
                "isTyping": true,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        } else {
            try await typingRef.setData([
                "isTyping": false,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        }
    }

    func listenForTyping(conversationID: String,
                         onChange: @escaping ([TypingStatus]) -> Void,
                         onError: @escaping (Error) -> Void) -> PresenceListeningToken? {
        let collection = typingCollection(conversationID: conversationID)
        let registration = collection.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            guard let documents = snapshot?.documents else {
                onChange([])
                return
            }

            let statuses: [TypingStatus] = documents.compactMap { doc in
                guard doc.documentID != self.currentUserID else { return nil }
                let data = doc.data()
                let isTyping = data["isTyping"] as? Bool ?? false
                let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
                return TypingStatus(userID: doc.documentID,
                                    isTyping: isTyping,
                                    updatedAt: updatedAt)
            }
            onChange(statuses)
        }
        return FirestorePresenceListener(registrations: [registration])
    }

    private func presenceDocument(for userID: String) -> DocumentReference {
        presenceCollection.document(userID)
    }

    private func typingCollection(conversationID: String) -> CollectionReference {
        db.collection("conversations")
            .document(conversationID)
            .collection("typing")
    }

    private func typingDocument(conversationID: String, userID: String) -> DocumentReference {
        typingCollection(conversationID: conversationID).document(userID)
    }
}

final class FirestorePresenceListener: PresenceListeningToken {
    private var registrations: [ListenerRegistration]

    init(registrations: [ListenerRegistration]) {
        self.registrations = registrations
    }

    func stop() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
    }
}
#else
final class FirestorePresenceService: PresenceService {
    init(currentUserID: String) {}

    func setUserOnline() async throws {
        throw UserServiceError.firebaseSDKMissing
    }

    func setUserOffline() async throws {
        throw UserServiceError.firebaseSDKMissing
    }

    func listenForPresence(userIDs: [String],
                           onChange: @escaping ([UserPresenceState]) -> Void,
                           onError: @escaping (Error) -> Void) -> PresenceListeningToken? {
        onError(UserServiceError.firebaseSDKMissing)
        return nil
    }

    func setTypingState(conversationID: String,
                        isTyping: Bool) async throws {
        throw UserServiceError.firebaseSDKMissing
    }

    func listenForTyping(conversationID: String,
                         onChange: @escaping ([TypingStatus]) -> Void,
                         onError: @escaping (Error) -> Void) -> PresenceListeningToken? {
        onError(UserServiceError.firebaseSDKMissing)
        return nil
    }
}
#endif

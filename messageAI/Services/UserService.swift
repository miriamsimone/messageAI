import Foundation

struct UserSearchResult: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let username: String
    let profilePictureURL: URL?
}

struct UserProfile: Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let username: String
    let profilePictureURL: URL?
}

protocol UserService {
    func upsertProfile(_ profile: UserProfile) async throws
    func fetchProfile(userID: String) async throws -> UserProfile?
    func searchUsers(byUsername username: String) async throws -> [UserSearchResult]
    func addContact(userID: String) async throws
    func removeContact(userID: String) async throws
    func fetchContacts() async throws -> [UserSearchResult]
}

enum UserServiceError: LocalizedError {
    case firebaseSDKMissing
    case documentNotFound
    case permissionDenied
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .firebaseSDKMissing:
            return "Firebase Firestore SDK missing. Add Firestore via Swift Package Manager."
        case .documentNotFound:
            return "Unable to find the requested user."
        case .permissionDenied:
            return "You do not have permission to perform this action."
        case .unknown(let message):
            return message
        }
    }
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

final class FirestoreUserService: UserService {
    private let db = Firestore.firestore()
    private let currentUserID: String

    init(currentUserID: String) {
        self.currentUserID = currentUserID
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        let document = db.collection("users").document(profile.id)
        var payload: [String: Any] = [
            "displayName": profile.displayName,
            "username": profile.username.lowercased(),
            "searchUsername": profile.username.lowercased(),
            "email": profile.email.lowercased(),
            "updatedAt": Timestamp(date: Date())
        ]

        if let url = profile.profilePictureURL?.absoluteString {
            payload["profilePictureURL"] = url
        } else {
            payload["profilePictureURL"] = FieldValue.delete()
        }

        try await document.setData(payload, merge: true)
    }

    func fetchProfile(userID: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users")
            .document(userID)
            .getDocument()

        guard let data = snapshot.data() else {
            return nil
        }

        let displayName = (data["displayName"] as? String)?.nilIfEmpty
        let username = (data["username"] as? String)?.nilIfEmpty
        let email = (data["email"] as? String)?.nilIfEmpty
        let profileURL = (data["profilePictureURL"] as? String).flatMap(URL.init)

        guard let resolvedEmail = email ?? snapshot.documentID.nilIfEmpty else {
            return nil
        }

        return UserProfile(id: snapshot.documentID,
                           email: resolvedEmail,
                           displayName: displayName ?? resolvedEmail,
                           username: username ?? resolvedEmail,
                           profilePictureURL: profileURL)
    }

    func searchUsers(byUsername username: String) async throws -> [UserSearchResult] {
        let normalized = username.lowercased()
        let snapshot = try await db.collection("users")
            .whereField("searchUsername", isGreaterThanOrEqualTo: normalized)
            .whereField("searchUsername", isLessThanOrEqualTo: normalized + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            guard let displayName = doc["displayName"] as? String,
                  let username = doc["username"] as? String else {
                return nil
            }
            let profileURL: URL?
            if let urlString = doc["profilePictureURL"] as? String {
                profileURL = URL(string: urlString)
            } else {
                profileURL = nil
            }
            return UserSearchResult(id: doc.documentID,
                                    displayName: displayName,
                                    username: username,
                                    profilePictureURL: profileURL)
        }
    }

    func addContact(userID: String) async throws {
        try await contactsCollection()
            .document(userID)
            .setData([
                "contactUserID": userID,
                "createdAt": Timestamp(date: Date())
            ], merge: true)
    }

    func removeContact(userID: String) async throws {
        try await contactsCollection()
            .document(userID)
            .delete()
    }

    func fetchContacts() async throws -> [UserSearchResult] {
        let snapshot = try await contactsCollection().getDocuments()
        let userIDs = snapshot.documents.compactMap { $0["contactUserID"] as? String }

        guard !userIDs.isEmpty else { return [] }

        let chunks = stride(from: 0, to: userIDs.count, by: 10).map {
            Array(userIDs[$0..<min($0 + 10, userIDs.count)])
        }

        var results: [UserSearchResult] = []
        for chunk in chunks {
            let contactsSnapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let chunkResults = contactsSnapshot.documents.compactMap { doc -> UserSearchResult? in
                guard let displayName = doc["displayName"] as? String,
                      let username = doc["username"] as? String else {
                    return nil
                }
                let profileURL: URL?
                if let urlString = doc["profilePictureURL"] as? String {
                    profileURL = URL(string: urlString)
                } else {
                    profileURL = nil
                }
                return UserSearchResult(id: doc.documentID,
                                        displayName: displayName,
                                        username: username,
                                        profilePictureURL: profileURL)
            }
            results.append(contentsOf: chunkResults)
        }

        return results
    }

    private func contactsCollection() -> CollectionReference {
        db.collection("users")
            .document(currentUserID)
            .collection("contacts")
    }
}
#else
final class FirestoreUserService: UserService {
    init(currentUserID: String) {}

    func upsertProfile(_ profile: UserProfile) async throws {
        throw UserServiceError.firebaseSDKMissing
    }

    func fetchProfile(userID: String) async throws -> UserProfile? {
        throw UserServiceError.firebaseSDKMissing
    }

    func searchUsers(byUsername username: String) async throws -> [UserSearchResult] {
        throw UserServiceError.firebaseSDKMissing
    }

    func addContact(userID: String) async throws {
        throw UserServiceError.firebaseSDKMissing
    }

    func removeContact(userID: String) async throws {
        throw UserServiceError.firebaseSDKMissing
    }

    func fetchContacts() async throws -> [UserSearchResult] {
        throw UserServiceError.firebaseSDKMissing
    }
}
#endif

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

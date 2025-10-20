import Foundation

struct AuthSession: Sendable, Equatable {
    let userID: String
    let email: String
    let displayName: String?
    let username: String?
    let photoURL: URL?
}

enum AuthError: LocalizedError {
    case firebaseSDKMissing
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .firebaseSDKMissing:
            return "Firebase SDK is not linked. Please add FirebaseAuth via Swift Package Manager or CocoaPods."
        case .userNotFound:
            return "No account found for the provided credentials."
        case .invalidCredentials:
            return "The email or password is incorrect."
        case .emailAlreadyInUse:
            return "An account already exists for this email."
        case .unknown(let message):
            return message
        }
    }
}

protocol AuthService: Sendable {
    var currentSession: AuthSession? { get }
    func refreshCurrentSession() async throws -> AuthSession?
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(email: String,
                password: String,
                displayName: String?,
                username: String?) async throws -> AuthSession
    func signOut() async throws
}

#if canImport(FirebaseAuth)
import FirebaseAuth

final class FirebaseAuthService: AuthService {
    private let auth = Auth.auth()

    var currentSession: AuthSession? {
        guard let user = auth.currentUser else { return nil }
        return AuthSession(userID: user.uid,
                           email: user.email ?? "",
                           displayName: user.displayName,
                           username: user.displayName, // placeholder until profile doc sync
                           photoURL: user.photoURL)
    }

    func refreshCurrentSession() async throws -> AuthSession? {
        guard let user = auth.currentUser else { return nil }
        try await user.reload()
        return currentSession
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        let result = try await auth.signIn(withEmail: email, password: password)
        return AuthSession(userID: result.user.uid,
                           email: result.user.email ?? email,
                           displayName: result.user.displayName,
                           username: result.user.displayName,
                           photoURL: result.user.photoURL)
    }

    func signUp(email: String,
                password: String,
                displayName: String?,
                username: String?) async throws -> AuthSession {
        let result = try await auth.createUser(withEmail: email, password: password)
        if let displayName {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
        }
        return AuthSession(userID: result.user.uid,
                           email: result.user.email ?? email,
                           displayName: displayName,
                           username: username,
                           photoURL: result.user.photoURL)
    }

    func signOut() async throws {
        try auth.signOut()
    }
}
#else
final class FirebaseAuthService: AuthService {
    var currentSession: AuthSession? { nil }

    func refreshCurrentSession() async throws -> AuthSession? {
        throw AuthError.firebaseSDKMissing
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw AuthError.firebaseSDKMissing
    }

    func signUp(email: String,
                password: String,
                displayName: String?,
                username: String?) async throws -> AuthSession {
        throw AuthError.firebaseSDKMissing
    }

    func signOut() async throws {
        throw AuthError.firebaseSDKMissing
    }
}
#endif

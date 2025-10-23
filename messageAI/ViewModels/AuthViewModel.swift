import Foundation
import Combine
import SwiftData

@MainActor
final class AuthViewModel: ObservableObject {
    enum Route: Equatable {
        case splash
        case signIn
        case signUp
        case username(AuthSession)
        case authenticated(AuthSession)
    }

    @Published private(set) var route: Route = .splash
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?
    @Published private(set) var activeSession: AuthSession?

    private let authService: AuthService
    private let userServiceFactory: (String) -> UserService
    private let presenceServiceFactory: (String) -> PresenceService
    private let modelContext: ModelContext
    @Published private(set) var presenceService: PresenceService?

    init(authService: AuthService = FirebaseAuthService(),
         userServiceFactory: @escaping (String) -> UserService = { FirestoreUserService(currentUserID: $0) },
         presenceServiceFactory: @escaping (String) -> PresenceService = { FirestorePresenceService(currentUserID: $0) },
         modelContext: ModelContext = ModelContext(ModelContainerProvider.shared)) {
        self.authService = authService
        self.userServiceFactory = userServiceFactory
        self.presenceServiceFactory = presenceServiceFactory
        self.modelContext = modelContext
        Task { [weak self] in
            await self?.loadInitialSession()
        }
    }

    func loadInitialSession() async {
        guard let session = authService.currentSession else {
            route = .signIn
            return
        }

        let updatedSession = await synchronizeProfileAfterAuth(for: session, fallbackUsername: session.username)
        configurePresenceService(for: updatedSession.userID)
        activeSession = updatedSession
        route = .authenticated(updatedSession)
    }

    func signIn(email: String, password: String) async {
        await executeAuthAction { [weak self] in
            guard let self else { return }
            let session = try await self.authService.signIn(email: email, password: password)
            let updatedSession = try await self.synchronizeProfile(for: session,
                                                                   fallbackUsername: session.username)
            self.configurePresenceService(for: updatedSession.userID)
            self.activeSession = updatedSession
            self.route = .authenticated(updatedSession)
        }
    }

    func signUp(email: String,
                password: String,
                displayName: String?,
                username: String?) async {
        await executeAuthAction { [weak self] in
            guard let self else { return }
            let session = try await self.authService.signUp(email: email,
                                                            password: password,
                                                            displayName: displayName,
                                                            username: username)

            let sanitizedName = sanitizedDisplayName(from: displayName,
                                                     fallback: session.displayName ?? session.email)
            let normalizedUsername = normalizedUsername(from: username)

            var updatedSession = session.updating(displayName: sanitizedName,
                                                  username: normalizedUsername ?? session.username)

            if let normalizedUsername {
                self.activeSession = updatedSession
                self.route = .authenticated(updatedSession)
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        let persisted = try await self.persistProfile(for: updatedSession,
                                                                      username: normalizedUsername,
                                                                      displayName: sanitizedName)
                        self.configurePresenceService(for: persisted.userID)
                        try? await self.presenceService?.setUserOnline()
                        await MainActor.run {
                            self.activeSession = persisted
                        }
                    } catch {
                        await MainActor.run {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            } else {
                self.configurePresenceService(for: updatedSession.userID)
                self.activeSession = updatedSession
                self.route = .username(updatedSession)
            }
        }
    }

    func signOut() async {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil

        do {
            let service = presenceService
            try? await service?.setUserOffline()
            try await authService.signOut()
            presenceService = nil
            activeSession = nil
            route = .signIn
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func completeUsernameSetup(username: String) async {
        guard let session = activeSession,
              let normalizedUsername = normalizedUsername(from: username) else {
            return
        }

        await executeAuthAction { [weak self] in
            guard let self else { return }
            let updatedSession = try await self.persistProfile(for: session,
                                                               username: normalizedUsername,
                                                               displayName: session.displayName)
            self.activeSession = updatedSession
            self.route = .authenticated(updatedSession)
        }
    }

    func navigateToSignUp() {
        guard !isProcessing else { return }
        errorMessage = nil
        route = .signUp
    }

    func navigateToSignIn() {
        guard !isProcessing else { return }
        errorMessage = nil
        route = .signIn
    }

    private func synchronizeProfileAfterAuth(for session: AuthSession,
                                             fallbackUsername: String?) async -> AuthSession {
        do {
            return try await synchronizeProfile(for: session, fallbackUsername: fallbackUsername)
        } catch {
            return session
        }
    }

    private func synchronizeProfile(for session: AuthSession,
                                    fallbackUsername: String?) async throws -> AuthSession {
        let service = makeUserService(for: session.userID)

        do {
            if let profile = try await service.fetchProfile(userID: session.userID) {
                try upsertLocalUser(profile)
                return session.updating(displayName: profile.displayName, username: profile.username)
            }
        } catch {
            if isOfflineError(error) {
                return session
            }
            throw error
        }

        guard let fallback = normalizedUsername(from: fallbackUsername) else {
            return session
        }

        return try await persistProfile(for: session,
                                        username: fallback,
                                        displayName: session.displayName)
    }

    private func persistProfile(for session: AuthSession,
                                username: String,
                                displayName: String?) async throws -> AuthSession {
        let resolvedDisplayName = sanitizedDisplayName(from: displayName,
                                                       fallback: session.displayName ?? session.email)
        let profile = UserProfile(id: session.userID,
                                  email: session.email,
                                  displayName: resolvedDisplayName,
                                  username: username,
                                  profilePictureURL: session.photoURL)

        let service = makeUserService(for: session.userID)
        do {
            try await service.upsertProfile(profile)
            try upsertLocalUser(profile)
            let updatedSession = session.updating(displayName: profile.displayName, username: profile.username)
            configurePresenceService(for: updatedSession.userID)
            return updatedSession
        } catch {
            if isOfflineError(error) {
                let updatedSession = session.updating(displayName: profile.displayName, username: profile.username)
                configurePresenceService(for: updatedSession.userID)
                return updatedSession
            }
            throw error
        }
    }

    private func makeUserService(for userID: String) -> UserService {
        userServiceFactory(userID)
    }

    private func upsertLocalUser(_ profile: UserProfile) throws {
        let remoteID = profile.id
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.remoteID == remoteID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.displayName = profile.displayName
            existing.username = profile.username
            existing.email = profile.email
            existing.profilePictureURL = profile.profilePictureURL
        } else {
            let user = User(remoteID: profile.id,
                            displayName: profile.displayName,
                            username: profile.username,
                            email: profile.email,
                            profilePictureURL: profile.profilePictureURL)
            modelContext.insert(user)
        }

        try modelContext.save()
    }

    private func executeAuthAction(_ work: @escaping () async throws -> Void) async {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        do {
            try await work()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func sanitizedDisplayName(from raw: String?, fallback: String) -> String {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedUsername(from raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.lowercased()
    }

    private func isOfflineError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet {
            return true
        }
        if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 14 {
            return true
        }
        return false
    }

    private func configurePresenceService(for userID: String) {
        presenceService = presenceServiceFactory(userID)
    }
}

private extension AuthSession {
    func updating(displayName: String?, username: String?) -> AuthSession {
        AuthSession(userID: userID,
                    email: email,
                    displayName: displayName ?? self.displayName,
                    username: username ?? self.username,
                    photoURL: photoURL)
    }
}

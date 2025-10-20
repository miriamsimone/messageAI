import Foundation
import Combine

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

    init(authService: AuthService = FirebaseAuthService()) {
        self.authService = authService
        Task { [weak self] in
            await self?.loadInitialSession()
        }
    }

    func loadInitialSession() async {
        if let session = authService.currentSession {
            activeSession = session
            route = .authenticated(session)
        } else {
            route = .signIn
        }
    }

    func signIn(email: String, password: String) async {
        await executeAuthAction { [weak self] in
            guard let self else { return }
            let session = try await self.authService.signIn(email: email, password: password)
            self.activeSession = session
            self.route = .authenticated(session)
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
            self.activeSession = session
            self.route = .username(session)
        }
    }

    func signOut() async {
        await executeAuthAction { [weak self] in
            guard let self else { return }
            try await self.authService.signOut()
            self.activeSession = nil
            self.route = .signIn
        }
    }

    func completeUsernameSetup(username: String) {
        guard var session = activeSession else { return }
        session = AuthSession(userID: session.userID,
                              email: session.email,
                              displayName: session.displayName,
                              username: username,
                              photoURL: session.photoURL)
        activeSession = session
        errorMessage = nil
        route = .authenticated(session)
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
}

import SwiftUI
import Combine
import SwiftData

struct MainTabView: View {
    private let session: AuthSession
    private let presenceService: PresenceService
    private let onSignOut: () -> Void
    @StateObject private var conversationViewModel: ConversationListViewModel
    @StateObject private var contactsViewModel: UserSearchViewModel
    @EnvironmentObject private var notificationService: NotificationService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = Tab.chats
    @State private var pendingNotificationRoute: NotificationRoute?

    init(session: AuthSession,
         modelContext: ModelContext,
         presenceService: PresenceService,
         onSignOut: @escaping () -> Void) {
        self.session = session
        self.presenceService = presenceService
        self.onSignOut = onSignOut
        _conversationViewModel = StateObject(wrappedValue: ConversationListViewModel(
            conversationService: FirestoreConversationService(
                currentUserID: session.userID,
                currentUserDisplayName: session.displayName ?? session.email,
                currentUsername: session.username
            ),
            modelContext: modelContext,
            currentUserID: session.userID
        ))
        _contactsViewModel = StateObject(wrappedValue: UserSearchViewModel(
            userService: FirestoreUserService(currentUserID: session.userID),
            modelContext: modelContext,
            currentUserID: session.userID
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationListView(viewModel: conversationViewModel,
                                 currentUserID: session.userID,
                                 presenceService: presenceService,
                                 pendingRoute: $pendingNotificationRoute)
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(Tab.chats)

            ContactsView(viewModel: contactsViewModel)
                .tabItem {
                    Label("Contacts", systemImage: "person.2")
                }
                .tag(Tab.contacts)

            ProfilePlaceholderView(session: session,
                                   onSignOut: onSignOut)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
        .task {
            try? await presenceService.setUserOnline()
        }
        .onChange(of: scenePhase) { phase in
            Task {
                switch phase {
                case .active:
                    try? await presenceService.setUserOnline()
                case .background:
                    try? await presenceService.setUserOffline()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
        .task {
            await notificationService.requestAuthorizationIfNeeded()
        }
        .onReceive(notificationService.$pendingRoute.compactMap { $0 }) { route in
            selectedTab = .chats
            pendingNotificationRoute = route
            notificationService.clearPendingRoute(id: route.id)
        }
    }
}

private struct ProfilePlaceholderView: View {
    let session: AuthSession
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.secondary)

            Text(session.displayName ?? session.email)
                .font(.title2)
                .fontWeight(.semibold)

            Text("@\(session.username ?? "username")")
                .foregroundStyle(.secondary)

            Button(role: .destructive, action: onSignOut) {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top, 16)

            Spacer()
        }
        .padding()
    }
}

private extension MainTabView {
    enum Tab: Hashable {
        case chats
        case contacts
        case profile
    }
}

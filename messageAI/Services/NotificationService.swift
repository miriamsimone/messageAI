import Foundation
import Combine
import UserNotifications
import UIKit

struct NotificationRoute: Identifiable, Equatable {
    let id: UUID
    let conversationID: String

    init(conversationID: String) {
        self.id = UUID()
        self.conversationID = conversationID
    }
}

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pendingRoute: NotificationRoute?
    @Published private(set) var apnsDeviceToken: String?
    @Published private(set) var lastRegistrationError: Error?

    private let center = UNUserNotificationCenter.current()
    private var hasConfigured = false

    private override init() {
        super.init()
    }

    func configure() {
        guard !hasConfigured else { return }
        hasConfigured = true
        center.delegate = self
        Task {
            await refreshAuthorizationStatus()
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await refreshAuthorizationStatus()
                if granted {
                    registerForRemoteNotifications()
                }
            } catch {
                lastRegistrationError = error
            }
        case .denied:
            break
        case .authorized, .provisional, .ephemeral:
            registerForRemoteNotifications()
        @unknown default:
            break
        }
    }

    func registerForRemoteNotifications() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func handleLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] else { return }
        Task { @MainActor in
            self.routeIfPossible(from: userInfo)
        }
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        Task { @MainActor in
            self.routeIfPossible(from: userInfo)
        }
    }

    func didRegisterForRemoteNotifications(deviceToken tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        apnsDeviceToken = token
        lastRegistrationError = nil
        // TODO: Upstream the token to Firestore once backend is ready.
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        lastRegistrationError = error
    }

    func clearPendingRoute(id: UUID? = nil) {
        guard let id else {
            pendingRoute = nil
            return
        }

        if pendingRoute?.id == id {
            pendingRoute = nil
        }
    }

    private func extractConversationID(from userInfo: [AnyHashable: Any]) -> String? {
        if let direct = userInfo["conversationId"] as? String {
            return direct
        }

        if let camelCase = userInfo["conversationID"] as? String {
            return camelCase
        }

        if let snakeCase = userInfo["conversation_id"] as? String {
            return snakeCase
        }

        if let data = userInfo["data"] as? [AnyHashable: Any] {
            if let nested = data["conversationId"] as? String {
                return nested
            }
            if let camelCase = data["conversationID"] as? String {
                return camelCase
            }
            if let snakeCase = data["conversation_id"] as? String {
                return snakeCase
            }
        }

        return nil
    }

    fileprivate func routeIfPossible(from userInfo: [AnyHashable: Any]) {
        guard let conversationID = extractConversationID(from: userInfo) else { return }
        pendingRoute = NotificationRoute(conversationID: conversationID)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            NotificationService.shared.routeIfPossible(from: response.notification.request.content.userInfo)
        }
        completionHandler()
    }
}

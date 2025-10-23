import Foundation
import Combine
import SwiftData

@MainActor
final class UserSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [UserSearchResult] = []
    @Published private(set) var contacts: [UserSearchResult] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let userService: UserService
    private let modelContext: ModelContext
    private let currentUserID: String
    private let debounceDelay: TimeInterval = 0.4
    private var lastTask: Task<Void, Never>?

    init(userService: UserService, modelContext: ModelContext, currentUserID: String) {
        self.userService = userService
        self.modelContext = modelContext
        self.currentUserID = currentUserID
        loadLocalContacts()
    }

    func refreshContacts() async {
        await perform {
            let remoteContacts = try await self.userService.fetchContacts()
            let sortedRemote = remoteContacts
                .filter { $0.id != self.currentUserID }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            try self.syncLocalContacts(with: sortedRemote)
            self.contacts = sortedRemote
        }
    }

    func updateQuery(_ newValue: String) {
        query = newValue
        lastTask?.cancel()
        guard !newValue.isEmpty else {
            results = []
            return
        }

        lastTask = Task { [weak self] in
            do {
                let interval = (self?.debounceDelay ?? 0) * 1_000_000_000
                try await Task.sleep(nanoseconds: UInt64(interval))
            } catch {
                return
            }

            guard !Task.isCancelled, let self else { return }
            await self.perform {
                let fetched = try await self.userService.searchUsers(byUsername: newValue)
                self.results = fetched.filter { $0.id != self.currentUserID }
            }
        }
    }

    func addContact(_ user: UserSearchResult) {
        Task { [weak self] in
            guard let self else { return }
            await self.perform {
                try await self.userService.addContact(userID: user.id)
                try self.upsertLocalContact(from: user)
                if !self.contacts.contains(user) {
                    self.contacts.append(user)
                }
            }
        }
    }

    func removeContact(_ user: UserSearchResult) {
        Task { [weak self] in
            guard let self else { return }
            await self.perform {
                try await self.userService.removeContact(userID: user.id)
                try self.deleteLocalContact(withID: user.id)
                self.contacts.removeAll { $0.id == user.id }
            }
        }
    }

    private func loadLocalContacts() {
        let descriptor = FetchDescriptor<Contact>()
        if let storedContacts = try? modelContext.fetch(descriptor) {
            contacts = storedContacts
                .filter { $0.ownerUserID == currentUserID }
                .sorted(by: { $0.displayName < $1.displayName })
                .map { contact in
                    UserSearchResult(id: contact.remoteID,
                                     displayName: contact.displayName,
                                     username: contact.username,
                                     profilePictureURL: contact.profilePictureURL)
                }
        }
    }

    private func syncLocalContacts(with remote: [UserSearchResult]) throws {
        let descriptor = FetchDescriptor<Contact>()
        let stored = try modelContext.fetch(descriptor).filter { $0.ownerUserID == currentUserID }
        var storedByID = Dictionary(uniqueKeysWithValues: stored.map { ($0.remoteID, $0) })
        let remoteIDs = Set(remote.map(\.id))

        for contact in remote {
            if let existing = storedByID.removeValue(forKey: contact.id) {
                existing.displayName = contact.displayName
                existing.username = contact.username
                existing.profilePictureURL = contact.profilePictureURL
            } else {
                let newContact = Contact(remoteID: contact.id,
                                         ownerUserID: currentUserID,
                                         contactUserID: contact.id,
                                         displayName: contact.displayName,
                                         username: contact.username,
                                         profilePictureURL: contact.profilePictureURL)
                modelContext.insert(newContact)
            }
        }

        for obsolete in storedByID.values where !remoteIDs.contains(obsolete.remoteID) {
            modelContext.delete(obsolete)
        }

        try modelContext.save()
    }

    private func upsertLocalContact(from result: UserSearchResult) throws {
        let descriptor = FetchDescriptor<Contact>()
        if let existing = try modelContext.fetch(descriptor).first(where: { $0.remoteID == result.id && $0.ownerUserID == currentUserID }) {
            existing.displayName = result.displayName
            existing.username = result.username
            existing.profilePictureURL = result.profilePictureURL
        } else {
            let contact = Contact(remoteID: result.id,
                                  ownerUserID: currentUserID,
                                  contactUserID: result.id,
                                  displayName: result.displayName,
                                  username: result.username,
                                  profilePictureURL: result.profilePictureURL)
            modelContext.insert(contact)
        }
        try modelContext.save()
    }

    private func deleteLocalContact(withID id: String) throws {
        let descriptor = FetchDescriptor<Contact>()
        if let existing = try modelContext.fetch(descriptor).first(where: { $0.remoteID == id && $0.ownerUserID == currentUserID }) {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    private func perform(_ operation: @escaping () async throws -> Void) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await operation()
        } catch let error as UserServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

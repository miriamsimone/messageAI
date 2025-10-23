import SwiftUI
import SwiftData

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var contacts: [Contact]

    private let isProcessing: Bool
    private let onCreate: (String, [Contact]) -> Void

    @State private var groupName: String = ""
    @State private var selectedContactIDs: Set<String> = []

    init(ownerUserID: String,
         isProcessing: Bool,
         onCreate: @escaping (String, [Contact]) -> Void) {
        self.isProcessing = isProcessing
        self.onCreate = onCreate
        _contacts = Query(filter: #Predicate<Contact> { $0.ownerUserID == ownerUserID },
                          sort: [SortDescriptor(\Contact.displayName, order: .forward)])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Details") {
                    TextField("Group name", text: $groupName)
                        .disabled(isProcessing)
                }

                Section("Members (minimum 2 contacts)") {
                    if contacts.isEmpty {
                        Text("Add contacts before creating a group.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(contacts, id: \.remoteID) { contact in
                            Button {
                                toggleSelection(for: contact)
                            } label: {
                                HStack {
                                    ContactRowView(user: contact.asSearchResult())
                                    Spacer()
                                    if selectedContactIDs.contains(contact.contactUserID) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .disabled(isProcessing)
                        }
                    }
                }
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: createGroup)
                        .disabled(!canCreateGroup || isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
    }

    private var canCreateGroup: Bool {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && selectedContactIDs.count >= 2
    }

    private func toggleSelection(for contact: Contact) {
        if selectedContactIDs.contains(contact.contactUserID) {
            selectedContactIDs.remove(contact.contactUserID)
        } else {
            selectedContactIDs.insert(contact.contactUserID)
        }
    }

    private func createGroup() {
        guard canCreateGroup else { return }
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let selected = contacts.filter { selectedContactIDs.contains($0.contactUserID) }
        onCreate(trimmedName, selected)
    }
}

private extension Contact {
    func asSearchResult() -> UserSearchResult {
        UserSearchResult(id: contactUserID,
                         displayName: displayName,
                         username: username,
                         profilePictureURL: profilePictureURL)
    }
}

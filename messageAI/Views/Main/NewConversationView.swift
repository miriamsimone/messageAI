import SwiftUI
import SwiftData

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var contacts: [Contact]

    private let isProcessing: Bool
    private let onSelect: (Contact) -> Void

    init(ownerUserID: String,
         isProcessing: Bool,
         onSelect: @escaping (Contact) -> Void) {
        self.isProcessing = isProcessing
        self.onSelect = onSelect
        _contacts = Query(filter: #Predicate<Contact> { $0.ownerUserID == ownerUserID },
                          sort: [SortDescriptor(\Contact.displayName, order: .forward)])
    }

    var body: some View {
        NavigationStack {
            List {
                if contacts.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("Add contacts to start conversations.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                    }
                } else {
                    Section("Contacts") {
                        ForEach(contacts, id: \.remoteID) { contact in
                            Button {
                                select(contact)
                            } label: {
                                ContactRowView(user: contact.asSearchResult())
                            }
                            .buttonStyle(.plain)
                            .disabled(isProcessing)
                        }
                    }
                }
            }
            .navigationTitle("New Conversation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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

    private func select(_ contact: Contact) {
        onSelect(contact)
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

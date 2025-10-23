import SwiftUI

struct ContactsView: View {
    @StateObject private var viewModel: UserSearchViewModel

    init(viewModel: UserSearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                searchField

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                List {
                    if !viewModel.contacts.isEmpty {
                        Section("Contacts") {
                            ForEach(viewModel.contacts) { contact in
                                ContactRowView(user: contact) {
                                    AnyView(
                                        Button(role: .destructive) {
                                            viewModel.removeContact(contact)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.borderless)
                                    )
                                }
                            }
                        }
                    }

                    if !viewModel.results.isEmpty {
                        Section("Search Results") {
                            ForEach(viewModel.results) { result in
                                ContactRowView(user: result) {
                                    AnyView(
                                        Button {
                                            viewModel.addContact(result)
                                        } label: {
                                            Image(systemName: viewModel.contacts.contains(result) ? "checkmark.circle.fill" : "plus.circle.fill")
                                                .foregroundStyle(viewModel.contacts.contains(result) ? .green : .accentColor)
                                        }
                                        .buttonStyle(.borderless)
                                        .disabled(viewModel.contacts.contains(result))
                                    )
                                }
                            }
                        }
                    }

                    if viewModel.results.isEmpty && viewModel.contacts.isEmpty && !viewModel.query.isEmpty {
                        Text("No users matched that username.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 32)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.refreshContacts()
                }
            }
            .padding(.horizontal, 16)
            .navigationTitle("Contacts")
        }
        .task {
            await viewModel.refreshContacts()
        }
    }

    private var searchField: some View {
        TextField("Search by username", text: Binding(
            get: { viewModel.query },
            set: { viewModel.updateQuery($0) }
        ))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

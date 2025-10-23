import SwiftUI

struct UsernameSetupView: View {
    @ObservedObject var viewModel: AuthViewModel
    let session: AuthSession

    @State private var username: String
    @FocusState private var isFocused: Bool

    init(viewModel: AuthViewModel, session: AuthSession) {
        self.viewModel = viewModel
        self.session = session
        _username = State(initialValue: session.username ?? "")
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a Username")
                    .font(.largeTitle.weight(.bold))

                Text("Your contacts will use this to find you. Usernames must be unique and at least three characters.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: completeUsername) {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Finish Setup")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || viewModel.isProcessing)

            Spacer()
        }
        .padding(24)
        .task {
            await MainActor.run {
                isFocused = true
            }
        }
    }

    private var isFormValid: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    private func completeUsername() {
        guard isFormValid, !viewModel.isProcessing else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await viewModel.completeUsernameSetup(username: trimmed)
        }
    }
}

#Preview {
    let session = AuthSession(userID: "123", email: "preview@example.com", displayName: "Preview", username: nil, photoURL: nil)
    UsernameSetupView(viewModel: AuthViewModel(), session: session)
}

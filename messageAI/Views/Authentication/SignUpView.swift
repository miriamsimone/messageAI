import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var username = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
        case displayName
        case username
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Register to start messaging with your contacts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)

                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .displayName)

                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)

                Text("Usernames must be unique and will be shown to contacts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .textFieldStyle(.roundedBorder)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: signUp) {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || viewModel.isProcessing)

            Button("Already have an account? Sign in") {
                viewModel.navigateToSignIn()
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
        .padding(24)
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                focusedField = .displayName
            case .displayName:
                focusedField = .username
            case .username, .none:
                signUp()
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty
    }

    private func signUp() {
        guard isFormValid, !viewModel.isProcessing else { return }
        Task {
            await viewModel.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                   password: password,
                                   displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                                   username: username.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    SignUpView(viewModel: AuthViewModel())
}


import SwiftUI

struct ContactRowView: View {
    let user: UserSearchResult
    let accessory: () -> AnyView

    init(user: UserSearchResult, accessory: @escaping () -> AnyView = { AnyView(EmptyView()) }) {
        self.user = user
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: 16) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            accessory()
        }
        .padding(.vertical, 8)
    }

    private var avatar: some View {
        Group {
            if let url = user.profilePictureURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Text(user.displayName.prefix(1)).font(.headline)
                    .foregroundStyle(.secondary)
            )
    }
}

#Preview {
    ContactRowView(user: UserSearchResult(id: "demo",
                                          displayName: "Miriam Flander",
                                          username: "miriam",
                                          profilePictureURL: nil)) {
        AnyView(Image(systemName: "plus"))
    }
}


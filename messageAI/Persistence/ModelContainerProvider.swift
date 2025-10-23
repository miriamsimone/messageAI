import SwiftData

enum ModelContainerProvider {
    static let shared: ModelContainer = {
        let schema = Schema([
            User.self,
            Conversation.self,
            Message.self,
            Contact.self
        ])

        // For development: Delete and recreate if migration fails
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // If migration fails during development, provide helpful error
            print("⚠️ ModelContainer initialization failed: \(error)")
            print("💡 To fix: Delete the app from simulator and reinstall")
            fatalError("Failed to create ModelContainer. Delete the app and reinstall. Error: \(error)")
        }
    }()
}

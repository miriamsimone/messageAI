import SwiftData

enum ModelContainerProvider {
    static let shared: ModelContainer = {
        let schema = Schema([
            User.self,
            Conversation.self,
            Message.self,
            TypingIndicator.self,
            Contact.self
        ])

        let configuration = ModelConfiguration()

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}


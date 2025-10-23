import Foundation

enum StorageServiceError: LocalizedError {
    case firebaseSDKMissing

    var errorDescription: String? {
        switch self {
        case .firebaseSDKMissing:
            return "Firebase Storage SDK is not linked. Add FirebaseStorage via Swift Package Manager."
        }
    }
}

protocol StorageService: Sendable {
    func uploadImage(data: Data,
                     conversationID: String,
                     fileName: String,
                     contentType: String) async throws -> URL
}

#if canImport(FirebaseStorage)
import FirebaseStorage

final class FirebaseStorageService: StorageService {
    private let storage = Storage.storage()
    private let currentUserID: String

    init(currentUserID: String) {
        self.currentUserID = currentUserID
    }

    func uploadImage(data: Data,
                     conversationID: String,
                     fileName: String,
                     contentType: String) async throws -> URL {
        let mediaPath = "conversations/\(conversationID)/media/\(currentUserID)/\(fileName)"
        let reference = storage.reference(withPath: mediaPath)
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await reference.putDataAsync(data, metadata: metadata)
        return try await reference.downloadURL()
    }
}
#else
final class FirebaseStorageService: StorageService {
    init(currentUserID: String) {}

    func uploadImage(data: Data,
                     conversationID: String,
                     fileName: String,
                     contentType: String) async throws -> URL {
        throw StorageServiceError.firebaseSDKMissing
    }
}
#endif

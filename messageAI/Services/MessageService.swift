import Foundation

struct ChatMessageItem: Identifiable, Equatable, Sendable {
    let id: String
    let conversationID: String
    let senderID: String
    let content: String
    let type: MessageContentType
    let mediaURL: URL?
    let timestamp: Date
    let deliveryStatus: MessageDeliveryStatus
    let readBy: [String]
    let localID: String?
}

protocol MessageListeningToken {
    func stop()
}

protocol MessageService {
    func listenForMessages(in conversationID: String,
                           onChange: @escaping ([ChatMessageItem]) -> Void,
                           onError: @escaping (Error) -> Void) -> MessageListeningToken

    func sendMessage(to conversationID: String,
                     content: String,
                     type: MessageContentType,
                     localID: String?,
                     metadata: [String: Any]?) async throws -> ChatMessageItem
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

final class FirestoreMessageService: MessageService {
    private let db = Firestore.firestore()
    private let currentUserID: String

    init(currentUserID: String) {
        self.currentUserID = currentUserID
    }

    func listenForMessages(in conversationID: String,
                           onChange: @escaping ([ChatMessageItem]) -> Void,
                           onError: @escaping (Error) -> Void) -> MessageListeningToken {
        let query = db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .order(by: "timestamp", descending: false)

        let registration = query.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            guard let documents = snapshot?.documents else {
                onChange([])
                return
            }

            let messages: [ChatMessageItem] = documents.compactMap { doc in
                let data = doc.data()
                guard let senderID = data["senderId"] as? String,
                      let typeString = data["type"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                      let statusString = data["deliveryStatus"] as? String else {
                    return nil
                }

                let type = MessageContentType(rawValue: typeString) ?? .text
                let status = MessageDeliveryStatus(rawValue: statusString) ?? .sent
                let mediaURL = (data["mediaURL"] as? String).flatMap(URL.init(string:))
                let readBy = data["readBy"] as? [String] ?? []
                let localID = data["localId"] as? String

                return ChatMessageItem(id: doc.documentID,
                                       conversationID: conversationID,
                                       senderID: senderID,
                                       content: data["content"] as? String ?? "",
                                       type: type,
                                       mediaURL: mediaURL,
                                       timestamp: timestamp,
                                       deliveryStatus: status,
                                       readBy: readBy,
                                       localID: localID)
            }

            onChange(messages)
        }

        return FirestoreListenerToken(registration: registration)
    }

    func sendMessage(to conversationID: String,
                     content: String,
                     type: MessageContentType,
                     localID: String?,
                     metadata: [String: Any]? = nil) async throws -> ChatMessageItem {
        let messagesRef = db.collection("conversations")
            .document(conversationID)
            .collection("messages")

        let newDoc = messagesRef.document()
        let now = Date()

        var payload: [String: Any] = [
            "senderId": currentUserID,
            "content": content,
            "type": type.rawValue,
            "timestamp": Timestamp(date: now),
            "deliveryStatus": MessageDeliveryStatus.sent.rawValue,
            "readBy": [currentUserID],
        ]

        if let mediaURL = metadata?["mediaURL"] as? String {
            payload["mediaURL"] = mediaURL
        }

        if let localID {
            payload["localId"] = localID
        }

        try await newDoc.setData(payload)

        let conversationRef = db.collection("conversations").document(conversationID)
        try await conversationRef.setData([
            "lastMessage": content,
            "lastMessageTimestamp": Timestamp(date: now),
            "lastMessageSenderId": currentUserID
        ], merge: true)

        return ChatMessageItem(id: newDoc.documentID,
                               conversationID: conversationID,
                               senderID: currentUserID,
                               content: content,
                               type: type,
                               mediaURL: (metadata?["mediaURL"] as? String).flatMap(URL.init(string:)),
                               timestamp: now,
                               deliveryStatus: .sent,
                               readBy: [currentUserID],
                               localID: localID)
    }
}
#else
final class FirestoreMessageService: MessageService {
    init(currentUserID: String) {}

    func listenForMessages(in conversationID: String,
                           onChange: @escaping ([ChatMessageItem]) -> Void,
                           onError: @escaping (Error) -> Void) -> MessageListeningToken {
        onError(UserServiceError.firebaseSDKMissing)
        return EmptyConversationListener()
    }

    func sendMessage(to conversationID: String,
                     content: String,
                     type: MessageContentType,
                     localID: String?,
                     metadata: [String: Any]? = nil) async throws -> ChatMessageItem {
        throw UserServiceError.firebaseSDKMissing
    }
}
#endif

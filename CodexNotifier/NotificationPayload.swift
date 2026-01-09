import Foundation

public struct NotificationPayload: Decodable {
    public let type: String?
    public let lastAssistantMessage: String?
    public let inputMessages: [String]?
    public let threadId: String?

    public var title: String {
        let message = lastAssistantMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message, !message.isEmpty {
            return "Codex: \(message)"
        }
        return "Codex: Turn Complete!"
    }

    public var message: String {
        inputMessages?.joined(separator: " ") ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case type
        case lastAssistantMessage = "last-assistant-message"
        case inputMessages = "input-messages"
        case threadId = "thread-id"
    }

    public static func decode(from jsonString: String) -> NotificationPayload? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NotificationPayload.self, from: data)
    }
}

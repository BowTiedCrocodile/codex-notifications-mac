import Foundation

struct NotificationPayload: Decodable {
    let type: String?
    let lastAssistantMessage: String?
    let inputMessages: [String]?
    let threadId: String?

    var title: String {
        let message = lastAssistantMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message, !message.isEmpty {
            return "Codex: \(message)"
        }
        return "Codex: Turn Complete!"
    }

    var message: String {
        inputMessages?.joined(separator: " ") ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case type
        case lastAssistantMessage = "last-assistant-message"
        case inputMessages = "input-messages"
        case threadId = "thread-id"
    }

    static func decode(from jsonString: String) -> NotificationPayload? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NotificationPayload.self, from: data)
    }
}

import Testing
import CodexNotifierCore

@Test
func decodePopulatesFieldsAndComputedProperties() throws {
    let json = """
    {
      "type": "agent-turn-complete",
      "last-assistant-message": "  Turn Complete!  ",
      "input-messages": ["First", "Second"],
      "thread-id": "abc"
    }
    """

    let payload = try #require(NotificationPayload.decode(from: json))

    #expect(payload.type == "agent-turn-complete")
    #expect(payload.threadId == "abc")
    #expect(payload.title == "Codex: Turn Complete!")
    #expect(payload.message == "First Second")
}

@Test
func decodeFallsBackWhenMessageMissing() throws {
    let json = """
    {
      "type": "agent-turn-complete"
    }
    """

    let payload = try #require(NotificationPayload.decode(from: json))

    #expect(payload.title == "Codex: Turn Complete!")
    #expect(payload.message == "")
}

@Test
func decodeReturnsNilForInvalidJSON() {
    let payload = NotificationPayload.decode(from: "{not-json}")
    #expect(payload == nil)
}

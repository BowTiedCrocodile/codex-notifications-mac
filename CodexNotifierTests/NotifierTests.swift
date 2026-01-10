import Foundation
import Testing
import UserNotifications
import CodexNotifierCore

private final class TestNotificationCenter: NotificationCentering {
    var requestedOptions: UNAuthorizationOptions?
    var nextAuthorizationResult: Bool = true
    var addedRequests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        requestedOptions = options
        completionHandler(nextAuthorizationResult, nil)
    }

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        addedRequests.append(request)
        completionHandler?(nil)
    }
}

@Test
func displayNameStripsExtension() {
    #expect(Notifier.displayName(for: "Glass.aiff") == "Glass")
}

@Test
func displayNameReturnsInputWhenNoExtension() {
    #expect(Notifier.displayName(for: "Basso") == "Basso")
}

@Test
func defaultSoundNameIsNonEmpty() {
    #expect(!Notifier.defaultSoundName().isEmpty)
}

@Test
func handlePayloadTriggersIconWhenEnabled() throws {
    let suiteName = "NotifierTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let notifier = Notifier(defaults: defaults)
    notifier.playSoundEnabled = false
    notifier.flashIconEnabled = true

    var states: [Bool] = []
    notifier.iconHandler = { states.append($0) }

    let payload = try #require(NotificationPayload.decode(from: "{\"type\":\"agent-turn-complete\"}"))
    notifier.handle(payload: payload)

    #expect(states.first == true)
}

@Test
func handlePayloadIgnoresOtherTypes() throws {
    let suiteName = "NotifierTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let notifier = Notifier(defaults: defaults)
    notifier.playSoundEnabled = false
    notifier.flashIconEnabled = true

    var didFlash = false
    notifier.iconHandler = { _ in didFlash = true }

    let payload = try #require(NotificationPayload.decode(from: "{\"type\":\"other\"}"))
    notifier.handle(payload: payload)

    #expect(didFlash == false)
}

@Test
func fileWatcherReportsOpenError() {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let missingURL = tempDir.appendingPathComponent("missing.json")
    var message: String?

    let watcher = FileWatcher(url: missingURL, handler: {}, errorHandler: { message = $0 })
    watcher.start()

    #expect(message?.contains("FileWatcher failed to open") == true)
}

@Test
func handlePayloadPostsNotificationWhenEnabled() throws {
    let suiteName = "NotifierTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let center = TestNotificationCenter()

    let notifier = Notifier(defaults: defaults, notificationCenter: center)
    notifier.showNotificationEnabled = true
    notifier.playSoundEnabled = false
    notifier.flashIconEnabled = false

    let json = """
    {
      "type": "agent-turn-complete",
      "last-assistant-message": "Hello",
      "input-messages": ["Ping"],
      "thread-id": "thread-1"
    }
    """
    let payload = try #require(NotificationPayload.decode(from: json))
    notifier.handle(payload: payload)

    #expect(center.addedRequests.count == 1)
    #expect(center.addedRequests.first?.content.title == "Codex: Hello")
    #expect(center.addedRequests.first?.content.body == "Ping")
    #expect(center.addedRequests.first?.content.threadIdentifier == "thread-1")
}

@Test
func requestNotificationAuthorizationUsesAlertOption() throws {
    let suiteName = "NotifierTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let center = TestNotificationCenter()
    center.nextAuthorizationResult = false

    let notifier = Notifier(defaults: defaults, notificationCenter: center)

    var granted: Bool?
    notifier.requestNotificationAuthorization { granted = $0 }

    #expect(center.requestedOptions == [.alert])
    #expect(granted == false)
}

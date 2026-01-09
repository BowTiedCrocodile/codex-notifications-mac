import Foundation
import Testing
import CodexNotifierCore

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

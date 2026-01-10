import Cocoa
import UserNotifications

public protocol NotificationCentering {
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
}

public struct SystemNotificationCenter: NotificationCentering {
    public init() {}

    public func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completionHandler)
    }

    public func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        UNUserNotificationCenter.current().add(request, withCompletionHandler: completionHandler)
    }
}

public final class Notifier {
    private enum Keys {
        static let playSound = "playSound"
        static let flashIcon = "flashIcon"
        static let soundName = "soundName"
        static let showNotification = "showNotification"
    }

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCentering
    private var resetWorkItem: DispatchWorkItem?

    public var iconHandler: ((Bool) -> Void)?

    public init(defaults: UserDefaults = .standard, notificationCenter: NotificationCentering = SystemNotificationCenter()) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        defaults.register(defaults: [
            Keys.playSound: true,
            Keys.flashIcon: true,
            Keys.soundName: Self.defaultSoundName(),
            Keys.showNotification: false,
        ])
    }

    public var playSoundEnabled: Bool {
        get { defaults.bool(forKey: Keys.playSound) }
        set { defaults.set(newValue, forKey: Keys.playSound) }
    }

    public var flashIconEnabled: Bool {
        get { defaults.bool(forKey: Keys.flashIcon) }
        set { defaults.set(newValue, forKey: Keys.flashIcon) }
    }

    public var soundName: String {
        get { defaults.string(forKey: Keys.soundName) ?? Self.defaultSoundName() }
        set { defaults.set(newValue, forKey: Keys.soundName) }
    }

    public var showNotificationEnabled: Bool {
        get { defaults.bool(forKey: Keys.showNotification) }
        set { defaults.set(newValue, forKey: Keys.showNotification) }
    }

    public func handle(jsonString: String) {
        guard let payload = NotificationPayload.decode(from: jsonString) else { return }
        handle(payload: payload)
    }

    public func handle(payload: NotificationPayload) {
        guard payload.type == "agent-turn-complete" else { return }

        if flashIconEnabled {
            flashIcon()
        }

        if playSoundEnabled {
            playSound()
        }

        if showNotificationEnabled {
            postNotification(title: payload.title, message: payload.message, threadId: payload.threadId)
        }
    }

    public func playTest() {
        flashIcon()
        playSound()
        if showNotificationEnabled {
            postNotification(title: "Codex: Test Notification", message: "Notifications are working.", threadId: "test")
        }
    }

    private func flashIcon() {
        iconHandler?(true)
        resetWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.iconHandler?(false)
        }
        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }

    private func playSound() {
        let name = soundName
        let sound = NSSound(named: NSSound.Name(name))
        sound?.play()
    }

    private func postNotification(title: String, message: String, threadId: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        if !message.isEmpty {
            content.body = message
        }
        if let threadId, !threadId.isEmpty {
            content.threadIdentifier = threadId
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        notificationCenter.add(request) { error in
            if let error {
                NSLog("Notification post failed: %@", error.localizedDescription)
            }
        }
    }

    public func requestNotificationAuthorization(completion: ((Bool) -> Void)? = nil) {
        notificationCenter.requestAuthorization(options: [.alert]) { granted, _ in
            completion?(granted)
        }
    }

    public static func availableSounds() -> [String] {
        let candidates = [
            "Basso",
            "Blow",
            "Bottle",
            "Frog",
            "Funk",
            "Glass",
            "Hero",
            "Morse",
            "Ping",
            "Pop",
            "Purr",
            "Sosumi",
            "Submarine",
            "Tink",
        ]
        let available = candidates.filter { NSSound(named: NSSound.Name($0)) != nil }
        if available.contains(defaultSoundName()) {
            return available
        }
        return available.isEmpty ? [defaultSoundName()] : available
    }

    public static func displayName(for soundName: String) -> String {
        if let dotIndex = soundName.lastIndex(of: ".") {
            return String(soundName[..<dotIndex])
        }
        return soundName
    }

    public static func defaultSoundName() -> String {
        return "Glass"
    }
}

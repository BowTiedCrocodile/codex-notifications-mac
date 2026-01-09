import Cocoa

public final class Notifier {
    private enum Keys {
        static let playSound = "playSound"
        static let flashIcon = "flashIcon"
        static let soundName = "soundName"
    }

    private let defaults = UserDefaults.standard
    private var resetWorkItem: DispatchWorkItem?

    public var iconHandler: ((Bool) -> Void)?

    public init() {
        defaults.register(defaults: [
            Keys.playSound: true,
            Keys.flashIcon: true,
            Keys.soundName: Self.defaultSoundName(),
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
    }

    public func playTest() {
        flashIcon()
        playSound()
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

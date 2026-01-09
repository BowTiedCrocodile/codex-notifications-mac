import Cocoa
import CodexNotifierCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let payloadFileName = "payload.json"
    private let normalSymbolName = "sparkles"
    private let alertSymbolName = "bell.badge.fill"

    private var statusItem: NSStatusItem!
    private var notifier: Notifier!
    private var fileWatcher: FileWatcher?

    private var playSoundItem: NSMenuItem?
    private var flashIconItem: NSMenuItem?
    private var soundMenu: NSMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        notifier = Notifier()
        notifier.iconHandler = { [weak self] isAlert in
            self?.updateStatusIcon(isAlert: isAlert)
        }

        setupStatusItem()
        refreshMenuStates()
        handleLaunchArguments()
        startFileWatcher()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon(isAlert: false)

        let menu = NSMenu()

        let playSound = NSMenuItem(title: "Play Sound", action: #selector(togglePlaySound), keyEquivalent: "")
        playSound.target = self
        menu.addItem(playSound)
        playSoundItem = playSound

        let flashIcon = NSMenuItem(title: "Flash Icon", action: #selector(toggleFlashIcon), keyEquivalent: "")
        flashIcon.target = self
        menu.addItem(flashIcon)
        flashIconItem = flashIcon

        menu.addItem(NSMenuItem.separator())

        let soundItem = NSMenuItem(title: "Sound", action: nil, keyEquivalent: "")
        let soundSubmenu = NSMenu()
        for soundName in Notifier.availableSounds() {
            let item = NSMenuItem(title: Notifier.displayName(for: soundName), action: #selector(selectSound), keyEquivalent: "")
            item.target = self
            item.representedObject = soundName
            soundSubmenu.addItem(item)
        }
        soundItem.submenu = soundSubmenu
        soundMenu = soundSubmenu
        menu.addItem(soundItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(title: "Test Notification", action: #selector(testNotification), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateStatusIcon(isAlert: Bool) {
        let symbolName = isAlert ? alertSymbolName : normalSymbolName
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Codex Notifier")
        statusItem.button?.image?.isTemplate = true
    }

    private func refreshMenuStates() {
        playSoundItem?.state = notifier.playSoundEnabled ? .on : .off
        flashIconItem?.state = notifier.flashIconEnabled ? .on : .off

        if let soundMenu = soundMenu {
            for item in soundMenu.items {
                let name = item.representedObject as? String
                item.state = (name == notifier.soundName) ? .on : .off
            }
        }
    }

    private func handleLaunchArguments() {
        let args = CommandLine.arguments.dropFirst()
        guard !args.isEmpty else { return }

        let payloadString: String
        if args.first == "--payload" {
            payloadString = args.dropFirst().joined(separator: " ")
        } else {
            payloadString = args.joined(separator: " ")
        }

        notifier.handle(jsonString: payloadString)
        refreshMenuStates()
    }

    private func startFileWatcher() {
        guard let payloadURL = payloadURL() else { return }
        FileManager.default.createFile(atPath: payloadURL.path, contents: nil)

        fileWatcher = FileWatcher(url: payloadURL) { [weak self] in
            self?.handlePayloadFile(at: payloadURL)
        }
        fileWatcher?.start()
    }

    private func handlePayloadFile(at url: URL) {
        guard let data = try? Data(contentsOf: url),
              let jsonString = String(data: data, encoding: .utf8),
              !jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        notifier.handle(jsonString: jsonString)
        refreshMenuStates()
    }

    private func payloadURL() -> URL? {
        guard let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appSupportURL = baseURL.appendingPathComponent("CodexNotifier", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        return appSupportURL.appendingPathComponent(payloadFileName)
    }

    @objc private func togglePlaySound(_ sender: NSMenuItem) {
        notifier.playSoundEnabled.toggle()
        refreshMenuStates()
    }

    @objc private func toggleFlashIcon(_ sender: NSMenuItem) {
        notifier.flashIconEnabled.toggle()
        refreshMenuStates()
    }

    @objc private func selectSound(_ sender: NSMenuItem) {
        guard let soundName = sender.representedObject as? String else { return }
        notifier.soundName = soundName
        refreshMenuStates()
        notifier.playTest()
    }

    @objc private func testNotification(_ sender: NSMenuItem) {
        notifier.playTest()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}

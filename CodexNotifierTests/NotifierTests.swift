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

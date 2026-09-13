import Testing

@testable import BrowserRouter

struct StarterConfigurationTests {
  @Test("Prefers a personal profile for a safe default")
  func prefersPersonalProfile() throws {
    let browser = ChromiumBrowser.helium
    let config = try StarterConfiguration.make(browsers: [browser]) { _ in
      [
        ChromiumProfile(displayName: "Work", directory: "Profile 2"),
        ChromiumProfile(displayName: "Personal", directory: "Default"),
      ]
    }

    #expect(config.browser == browser)
    #expect(config.defaultProfile == "Personal")
    #expect(config.rules.isEmpty)
  }

  @Test("Rejects setup without an installed browser")
  func rejectsMissingBrowser() {
    #expect(throws: ConfigError.self) {
      try StarterConfiguration.make(browsers: []) { _ in [] }
    }
  }
}

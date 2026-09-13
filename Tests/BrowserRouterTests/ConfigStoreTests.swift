import Foundation
import Testing

@testable import BrowserRouter

struct ConfigStoreTests {
  @Test("Reports when no configuration exists")
  func reportsMissingConfig() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("config.json")
    let store = ConfigStore(configURL: url)

    #expect(!store.load())
    #expect(store.config == nil)
    #expect(store.error as? ConfigError == .missing)
  }

  @Test("Saves and reloads configuration")
  func savesConfig() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("config.json")
    let store = ConfigStore(configURL: url)
    let config = TestFixtures.workConfig

    try store.save(config)

    #expect(store.load())
    #expect(store.config == config)
  }

  @Test("Loads pre-browser configs as Helium configs")
  func loadsLegacyHeliumConfig() throws {
    let json = #"{"defaultProfile":"Personal","rules":[]}"#
    let config = try JSONDecoder().decode(RouterConfig.self, from: Data(json.utf8))

    #expect(config.browser == nil)
    #expect(config.selectedBrowser == .helium)
  }

  @Test("Rejects malformed JSON without retaining a config")
  func rejectsMalformedJSON() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("config.json")
    try Data("not json".utf8).write(to: url)
    let store = ConfigStore(configURL: url)

    #expect(!store.load())
    #expect(store.config == nil)
    #expect(store.error != nil)
  }

  @Test("Migrates the legacy Application Support configuration")
  func migratesLegacyConfig() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let home = root.appendingPathComponent("home")
    let appSupport = root.appendingPathComponent("Application Support")
    let legacyURL =
      appSupport
      .appendingPathComponent("dev.36labs.browser-router")
      .appendingPathComponent("config.json")
    try FileManager.default.createDirectory(
      at: legacyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    try encoder.encode(TestFixtures.workConfig).write(to: legacyURL)

    let store = ConfigStore(homeDirectory: home, applicationSupportDirectory: appSupport)

    #expect(store.load())
    #expect(FileManager.default.fileExists(atPath: store.configURL.path))
    #expect(!FileManager.default.fileExists(atPath: legacyURL.path))
    #expect(store.config?.defaultProfile == "Personal")
  }

  @Test("Rejects ambiguous path prefixes")
  func validatesPathPrefix() throws {
    let match = URLMatch(host: "example.com", includeSubdomains: false, pathPrefix: "work")
    #expect(throws: ConfigError.self) {
      try match.validate(index: 0)
    }
  }
}

import Foundation
import Testing

@testable import Rootie

@MainActor
struct RootieCLITests {
  @Test("App launches normally without CLI arguments")
  func detectsCLIInvocation() {
    #expect(!RootieCLI.shouldRun(arguments: [], executablePath: "/app/Rootie"))
    #expect(
      RootieCLI.shouldRun(arguments: [], executablePath: "/opt/homebrew/bin/rootie"))
    #expect(
      RootieCLI.shouldRun(arguments: ["validate"], executablePath: "/app/Rootie"))
    #expect(
      !RootieCLI.shouldRun(arguments: ["-psn_0_123"], executablePath: "/app/Rootie"))
  }

  @Test("Non-interactive setup saves the selected browser and profile")
  func setupWithOptions() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let browser = ChromiumBrowser.helium
    let profiles = [ChromiumProfile(displayName: "Personal", directory: "Default")]

    let status = fixture.cli(
      arguments: ["setup", "--browser", "Helium", "--profile", "Personal"],
      browsers: [browser], profiles: profiles
    ).run()

    #expect(status == 0)
    #expect(fixture.store.load())
    #expect(fixture.store.config?.browser == browser)
    #expect(fixture.store.config?.defaultProfile == "Personal")
  }

  @Test("Setup preserves existing routing rules")
  func setupPreservesRules() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.store.save(TestFixtures.workConfig)

    let status = fixture.cli(
      arguments: ["setup", "--browser", "Helium", "--profile", "Personal"],
      browsers: [.helium],
      profiles: [ChromiumProfile(displayName: "Personal", directory: "Default")]
    ).run()

    #expect(status == 0)
    #expect(fixture.store.load())
    #expect(fixture.store.config?.rules == TestFixtures.workConfig.rules)
  }

  @Test("Validation checks referenced browser profiles")
  func validatesProfiles() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.store.save(
      RouterConfig(browser: .helium, defaultProfile: "Missing", rules: []))

    let status = fixture.cli(
      arguments: ["validate"], browsers: [.helium],
      profiles: [ChromiumProfile(displayName: "Personal", directory: "Default")]
    ).run()

    #expect(status == 1)
    #expect(fixture.errors.contains(where: { $0.contains("Missing") }))
  }

  @Test("Setup does not overwrite malformed JSON")
  func setupPreservesMalformedConfig() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try Data("not json".utf8).write(to: fixture.store.configURL)

    let status = fixture.cli(
      arguments: ["setup", "--browser", "Helium", "--profile", "Personal"],
      browsers: [.helium],
      profiles: [ChromiumProfile(displayName: "Personal", directory: "Default")]
    ).run()

    #expect(status == 1)
    #expect(try String(contentsOf: fixture.store.configURL, encoding: .utf8) == "not json")
  }
}

@MainActor
private final class Fixture {
  let directory: URL
  let store: ConfigStore
  var output: [String] = []
  var errors: [String] = []

  init() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    store = ConfigStore(configURL: directory.appendingPathComponent("config.json"))
  }

  func cli(
    arguments: [String], browsers: [ChromiumBrowser], profiles: [ChromiumProfile]
  ) -> RootieCLI {
    RootieCLI(
      arguments: arguments,
      configStore: store,
      installedBrowsers: { browsers },
      profiles: { _ in profiles },
      readInput: { nil },
      output: { self.output.append($0) },
      errorOutput: { self.errors.append($0) },
      openFile: { _ in })
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}

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

  @Test("Reads the version from the app bundle when invoked through a CLI symlink")
  func readsBundledVersion() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let app = directory.appendingPathComponent("Rootie.app")
    let contents = app.appendingPathComponent("Contents")
    let executable = contents.appendingPathComponent("MacOS/Rootie")
    let bin = directory.appendingPathComponent("bin")
    let symlink = bin.appendingPathComponent("rootie")
    try FileManager.default.createDirectory(
      at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
    let plist: [String: Any] = [
      "CFBundleExecutable": "Rootie",
      "CFBundleIdentifier": "io.github.hmbakhsh.rootie.test",
      "CFBundlePackageType": "APPL",
      "CFBundleShortVersionString": "1.2.3",
    ]
    let data = try PropertyListSerialization.data(
      fromPropertyList: plist, format: .xml, options: 0)
    try data.write(to: contents.appendingPathComponent("Info.plist"))
    FileManager.default.createFile(
      atPath: executable.path, contents: Data(),
      attributes: [.posixPermissions: 0o755])
    try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: executable)

    #expect(RootieCLI.version(executablePath: "rootie", searchPath: bin.path) == "1.2.3")
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

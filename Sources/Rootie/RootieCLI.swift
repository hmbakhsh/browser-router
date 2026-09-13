import AppKit
import Foundation

@MainActor
struct RootieCLI {
  static let commandName = "rootie"

  let arguments: [String]
  let configStore: ConfigStore
  let installedBrowsers: () -> [ChromiumBrowser]
  let profiles: (ChromiumBrowser) throws -> [ChromiumProfile]
  let readInput: () -> String?
  let output: (String) -> Void
  let errorOutput: (String) -> Void
  let openFile: @MainActor (URL) throws -> Void

  init(
    arguments: [String],
    configStore: ConfigStore = ConfigStore(),
    installedBrowsers: @escaping () -> [ChromiumBrowser] = { BrowserCatalog.installed() },
    profiles: @escaping (ChromiumBrowser) throws -> [ChromiumProfile] = {
      try ChromiumProfiles(browser: $0).all()
    },
    readInput: @escaping () -> String? = { readLine() },
    output: @escaping (String) -> Void = { print($0) },
    errorOutput: @escaping (String) -> Void = { message in
      FileHandle.standardError.write(Data("\(message)\n".utf8))
    },
    openFile: @escaping @MainActor (URL) throws -> Void = RootieCLI.openInTextEditor
  ) {
    self.arguments = arguments
    self.configStore = configStore
    self.installedBrowsers = installedBrowsers
    self.profiles = profiles
    self.readInput = readInput
    self.output = output
    self.errorOutput = errorOutput
    self.openFile = openFile
  }

  static func shouldRun(arguments: [String], executablePath: String) -> Bool {
    if URL(fileURLWithPath: executablePath).lastPathComponent == commandName { return true }
    guard let command = arguments.first else { return false }
    return [
      "help", "--help", "-h", "version", "--version", "-v", "browsers", "profiles", "setup",
      "init", "config", "validate", "default",
    ].contains(command)
  }

  func run() -> Int32 {
    let command = arguments.first ?? "help"
    do {
      switch command {
      case "help", "--help", "-h": output(Self.help)
      case "version", "--version", "-v": output(Self.version)
      case "browsers": try listBrowsers()
      case "profiles": try listProfiles()
      case "setup", "init": try setup()
      case "config": try openConfiguration()
      case "validate": try validate()
      case "default": try makeDefault()
      default:
        throw CLIError.usage("Unknown command “\(command)”. Run rootie help.")
      }
      return 0
    } catch {
      errorOutput(error.localizedDescription)
      return error is CLIError ? 64 : 1
    }
  }

  private func listBrowsers() throws {
    let browsers = availableBrowsers()
    guard !browsers.isEmpty else { throw CLIError.noBrowsers }
    for browser in browsers {
      output("\(browser.name)\t\(browser.applicationPath)")
    }
  }

  private func listProfiles() throws {
    let browser = try selectedBrowser()
    for profile in try profiles(browser) {
      output("\(profile.displayName)\t\(profile.directory)")
    }
  }

  private func setup() throws {
    let existing: RouterConfig?
    if configStore.load() {
      existing = configStore.config
    } else if configStore.error as? ConfigError == .missing {
      existing = nil
    } else {
      throw configStore.error ?? ConfigError.missing
    }
    let browsers = availableBrowsers(existing: existing)
    guard !browsers.isEmpty else { throw CLIError.noBrowsers }

    let options = try parsedOptions()
    let browser = try chooseBrowser(from: browsers, requested: options["browser"])
    let availableProfiles = try profiles(browser)
    guard !availableProfiles.isEmpty else {
      throw CLIError.usage("No profiles found for \(browser.name). Open it once and try again.")
    }
    let profile = try chooseProfile(
      from: availableProfiles,
      requested: options["profile"],
      preferred: existing?.defaultProfile)

    try configStore.save(
      RouterConfig(
        browser: browser,
        defaultProfile: profile.displayName,
        rules: existing?.rules ?? []))
    output("Saved \(configStore.configURL.path)")
    output("Browser: \(browser.name)")
    output("Default profile: \(profile.displayName)")
    if existing?.rules.isEmpty != false {
      output("Add routing rules with rootie config, then run rootie validate.")
    }
  }

  private func openConfiguration() throws {
    if !configStore.load() {
      guard configStore.error as? ConfigError == .missing else {
        throw configStore.error ?? ConfigError.missing
      }
      try configStore.save(
        StarterConfiguration.make(browsers: installedBrowsers(), profiles: profiles))
    }
    try openFile(configStore.configURL)
    output(configStore.configURL.path)
  }

  private func validate() throws {
    guard configStore.load() else { throw configStore.error ?? ConfigError.missing }
    guard let config = configStore.config else { throw ConfigError.missing }
    let availableProfiles = try profiles(config.selectedBrowser)
    try validateProfile(config.defaultProfile, in: availableProfiles)
    for rule in config.rules {
      try validateProfile(rule.profile, in: availableProfiles)
    }
    output("Configuration is valid: \(configStore.configURL.path)")
  }

  private func validateProfile(_ name: String, in profiles: [ChromiumProfile]) throws {
    guard profiles.contains(where: { $0.displayName == name }) else {
      throw ChromiumError.profileNotFound(name)
    }
  }

  private func makeDefault() throws {
    guard let appURL = Self.applicationURL() else {
      throw CLIError.usage("Could not locate Rootie.app from this executable.")
    }

    var result: Result<Void, Error>?
    DefaultBrowserSetter().makeDefault(appURL: appURL) { error in
      result = error.map { .failure($0) } ?? .success(())
    }
    while result == nil {
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
    }
    try result?.get()
    output("Rootie is now the default browser.")
  }

  private func availableBrowsers(existing: RouterConfig? = nil) -> [ChromiumBrowser] {
    var browsers = installedBrowsers()
    if let configured = existing?.selectedBrowser,
      !browsers.contains(where: { $0.applicationPath == configured.applicationPath })
    {
      browsers.append(configured)
    }
    return browsers
  }

  private func selectedBrowser() throws -> ChromiumBrowser {
    let options = try parsedOptions()
    if let name = options["browser"] {
      return try browser(named: name, in: availableBrowsers())
    }
    if configStore.load(), let browser = configStore.config?.selectedBrowser {
      return browser
    }
    guard let browser = availableBrowsers().first else { throw CLIError.noBrowsers }
    return browser
  }

  private func chooseBrowser(
    from browsers: [ChromiumBrowser], requested: String?
  ) throws -> ChromiumBrowser {
    if let requested { return try browser(named: requested, in: browsers) }
    return try prompt(
      "Chromium browser", items: browsers,
      preferred: configStore.config?.selectedBrowser.name,
      label: \ChromiumBrowser.name)
  }

  private func chooseProfile(
    from profiles: [ChromiumProfile], requested: String?, preferred: String?
  ) throws -> ChromiumProfile {
    if let requested {
      guard
        let profile = profiles.first(where: {
          $0.displayName.localizedCaseInsensitiveCompare(requested) == .orderedSame
        })
      else {
        throw CLIError.usage("No profile named “\(requested)” was found.")
      }
      return profile
    }
    return try prompt(
      "Default profile", items: profiles,
      preferred: preferred ?? StarterConfiguration.preferredProfile(in: profiles)?.displayName,
      label: \ChromiumProfile.displayName)
  }

  private func prompt<T>(
    _ title: String, items: [T], preferred: String?, label: KeyPath<T, String>
  ) throws -> T {
    output("\(title):")
    for (index, item) in items.enumerated() {
      let marker = item[keyPath: label] == preferred ? " (default)" : ""
      output("  \(index + 1)) \(item[keyPath: label])\(marker)")
    }
    output("Enter a number:")
    guard let input = readInput()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
      throw CLIError.usage("No selection received.")
    }
    if input.isEmpty, let preferred,
      let item = items.first(where: { $0[keyPath: label] == preferred })
    {
      return item
    }
    guard let index = Int(input), items.indices.contains(index - 1) else {
      throw CLIError.usage("Enter a number between 1 and \(items.count).")
    }
    return items[index - 1]
  }

  private func browser(named name: String, in browsers: [ChromiumBrowser]) throws
    -> ChromiumBrowser
  {
    guard
      let browser = browsers.first(where: {
        $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
      })
    else {
      throw CLIError.usage("No installed browser named “\(name)” was found.")
    }
    return browser
  }

  private func parsedOptions() throws -> [String: String] {
    var options: [String: String] = [:]
    var index = 1
    while index < arguments.count {
      let option = arguments[index]
      guard ["--browser", "--profile"].contains(option), index + 1 < arguments.count else {
        throw CLIError.usage("Unknown or incomplete option “\(option)”.")
      }
      options[String(option.dropFirst(2))] = arguments[index + 1]
      index += 2
    }
    return options
  }

  private static func openInTextEditor(_ url: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = ["-t", url.path]
    try process.run()
  }

  static func applicationURL(executablePath: String = CommandLine.arguments[0]) -> URL? {
    let executable = URL(fileURLWithPath: executablePath).resolvingSymlinksInPath()
    let app = executable.deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent()
    return app.pathExtension == "app" ? app : nil
  }

  static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
      ?? "development"
  }

  static let help = """
    Rootie routes external links to Chromium profiles.

    Usage: rootie <command> [options]

      setup                         Configure browser and default profile
      browsers                      List detected Chromium browsers
      profiles [--browser NAME]     List profiles
      config                        Open ~/.rootie/config.json
      validate                      Validate JSON and referenced profiles
      default                       Make Rootie the default browser
      version                       Print the installed version
      help                          Show this help

    Setup options:
      --browser NAME                Select a browser without prompting
      --profile NAME                Select a profile without prompting
    """
}

enum CLIError: LocalizedError {
  case noBrowsers
  case usage(String)

  var errorDescription: String? {
    switch self {
    case .noBrowsers:
      "No supported Chromium browser was found. Install and open one, then try again."
    case .usage(let message):
      message
    }
  }
}

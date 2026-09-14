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
      "init", "config", "validate", "default", "rules",
    ].contains(command)
  }

  func run() -> Int32 {
    let command = arguments.first ?? "help"
    do {
      switch command {
      case "help", "--help", "-h": output(Self.help)
      case "version", "--version", "-v": output(Self.version())
      case "browsers": try listBrowsers()
      case "profiles": try listProfiles()
      case "setup", "init": try setup()
      case "config": try openConfiguration()
      case "validate": try validate()
      case "default": try makeDefault()
      case "rules": try manageRules()
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

  private func manageRules() throws {
    guard arguments.count >= 2 else {
      throw CLIError.usage("Usage: rootie rules <list|add> [options]")
    }

    switch arguments[1] {
    case "list":
      guard arguments.count == 2 else {
        throw CLIError.usage("Usage: rootie rules list")
      }
      try listRules()
    case "add":
      try addRule()
    default:
      throw CLIError.usage("Unknown rules command “\(arguments[1])”. Use list or add.")
    }
  }

  private func listRules() throws {
    guard configStore.load(), let config = configStore.config else {
      throw configStore.error ?? ConfigError.missing
    }

    if config.rules.isEmpty {
      output("No routing rules configured.")
      return
    }

    for (index, rule) in config.rules.enumerated() {
      var matcher = rule.match.host
      if rule.match.includeSubdomains { matcher += " + subdomains" }
      if let pathPrefix = rule.match.pathPrefix { matcher += pathPrefix }
      let disabled = rule.enabled ? "" : " (disabled)"
      output("\(index + 1)\t\(rule.name)\(disabled)\t\(rule.profile)\t\(matcher)")
    }
  }

  private func addRule() throws {
    guard configStore.load(), let config = configStore.config else {
      throw configStore.error ?? ConfigError.missing
    }

    let parsed = try parsedRuleOptions()
    guard let rawHost = parsed.values["host"] else {
      throw CLIError.usage("Missing required option --host.")
    }
    guard let requestedProfile = parsed.values["profile"] else {
      throw CLIError.usage("Missing required option --profile.")
    }

    let host = URLMatch.normalizeHost(rawHost)
    let availableProfiles = try profiles(config.selectedBrowser)
    let profile = try chooseProfile(
      from: availableProfiles, requested: requestedProfile, preferred: nil)

    let pathPrefix = parsed.values["path-prefix"]
    let name = parsed.values["name"] ?? [host, pathPrefix].compactMap { $0 }.joined()
    let rule = RoutingRule(
      name: name,
      profile: profile.displayName,
      enabled: true,
      match: URLMatch(
        host: host,
        includeSubdomains: parsed.flags.contains("include-subdomains"),
        pathPrefix: pathPrefix))

    let position: Int
    if let rawPosition = parsed.values["position"] {
      guard
        let requestedPosition = Int(rawPosition),
        (1...(config.rules.count + 1)).contains(requestedPosition)
      else {
        throw CLIError.usage("--position must be between 1 and \(config.rules.count + 1).")
      }
      position = requestedPosition
    } else {
      position = config.rules.count + 1
    }

    var rules = config.rules
    rules.insert(rule, at: position - 1)
    try configStore.save(
      RouterConfig(browser: config.browser, defaultProfile: config.defaultProfile, rules: rules))
    output("Added rule \(position): \(name) → \(profile.displayName)")
    output("Run ‘rootie rules list’ to review precedence.")
  }

  private func parsedRuleOptions() throws -> (values: [String: String], flags: Set<String>) {
    try parseOptions(
      startingAt: 2,
      valueOptions: ["--host", "--profile", "--name", "--path-prefix", "--position"],
      flagOptions: ["--include-subdomains"])
  }

  private func parseOptions(
    startingAt startIndex: Int, valueOptions: Set<String>, flagOptions: Set<String> = []
  ) throws -> (values: [String: String], flags: Set<String>) {
    var values: [String: String] = [:]
    var flags: Set<String> = []
    var index = startIndex

    while index < arguments.count {
      let option = arguments[index]
      if flagOptions.contains(option) {
        guard !flags.contains(String(option.dropFirst(2))) else {
          throw CLIError.usage("Option “\(option)” was provided more than once.")
        }
        flags.insert(String(option.dropFirst(2)))
        index += 1
      } else if valueOptions.contains(option), index + 1 < arguments.count {
        let key = String(option.dropFirst(2))
        guard values[key] == nil else {
          throw CLIError.usage("Option “\(option)” was provided more than once.")
        }
        values[key] = arguments[index + 1]
        index += 2
      } else {
        throw CLIError.usage("Unknown or incomplete option “\(option)”.")
      }
    }

    return (values, flags)
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
    try parseOptions(startingAt: 1, valueOptions: ["--browser", "--profile"]).values
  }

  private static func openInTextEditor(_ url: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = ["-t", url.path]
    try process.run()
  }

  static func applicationURL(
    executablePath: String = CommandLine.arguments[0],
    searchPath: String? = ProcessInfo.processInfo.environment["PATH"]
  ) -> URL? {
    let executable = executableURL(executablePath: executablePath, searchPath: searchPath)
    let app = executable.deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent()
    return app.pathExtension == "app" ? app : nil
  }

  private static func executableURL(executablePath: String, searchPath: String?) -> URL {
    if executablePath.contains("/") {
      return URL(fileURLWithPath: executablePath).resolvingSymlinksInPath()
    }
    if let searchPath {
      for directory in searchPath.split(separator: ":") {
        let candidate = URL(fileURLWithPath: String(directory), isDirectory: true)
          .appendingPathComponent(executablePath)
        if FileManager.default.isExecutableFile(atPath: candidate.path) {
          return candidate.resolvingSymlinksInPath()
        }
      }
    }
    return URL(fileURLWithPath: executablePath).resolvingSymlinksInPath()
  }

  static func version(
    executablePath: String = CommandLine.arguments[0],
    searchPath: String? = ProcessInfo.processInfo.environment["PATH"]
  ) -> String {
    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
      as? String
    {
      return version
    }
    guard let appURL = applicationURL(executablePath: executablePath, searchPath: searchPath),
      let bundle = Bundle(url: appURL),
      let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    else {
      return "development"
    }
    return version
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
      rules list                    List rules in precedence order
      rules add [options]           Add a routing rule
      version                       Print the installed version
      help                          Show this help

    Setup options:
      --browser NAME                Select a browser without prompting
      --profile NAME                Select a profile without prompting

    Rules add options:
      --host HOST                   Hostname to match (required)
      --profile NAME                Destination profile (required)
      --name NAME                   Human-readable rule name
      --include-subdomains          Match subdomains of the host
      --path-prefix PATH            Match only this URL path
      --position NUMBER             Insert at this 1-based precedence position
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

import Foundation

struct RouterConfig: Codable, Equatable {
  let browser: ChromiumBrowser?
  let defaultProfile: String
  let rules: [RoutingRule]

  init(browser: ChromiumBrowser? = nil, defaultProfile: String, rules: [RoutingRule]) {
    self.browser = browser
    self.defaultProfile = defaultProfile
    self.rules = rules
  }

  var selectedBrowser: ChromiumBrowser { browser ?? .helium }

  func validate() throws {
    guard !defaultProfile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ConfigError.invalid("defaultProfile cannot be empty")
    }

    for (index, rule) in rules.enumerated() {
      try rule.validate(index: index)
    }
  }
}

struct RoutingRule: Codable, Equatable {
  let name: String
  let profile: String
  let enabled: Bool
  let match: URLMatch

  func validate(index: Int) throws {
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ConfigError.invalid("rules[\(index)].name cannot be empty")
    }
    guard !profile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ConfigError.invalid("rules[\(index)].profile cannot be empty")
    }
    try match.validate(index: index)
  }
}

struct URLMatch: Codable, Equatable {
  let host: String
  let includeSubdomains: Bool
  let pathPrefix: String?

  func validate(index: Int) throws {
    let normalizedHost = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    guard !normalizedHost.isEmpty,
      !normalizedHost.contains("/"),
      !normalizedHost.contains(":")
    else {
      throw ConfigError.invalid("rules[\(index)].match.host is not a valid hostname")
    }

    if let pathPrefix, !pathPrefix.hasPrefix("/") {
      throw ConfigError.invalid("rules[\(index)].match.pathPrefix must begin with /")
    }
  }
}

enum ConfigError: LocalizedError, Equatable {
  case invalid(String)
  case missing

  var errorDescription: String? {
    switch self {
    case .invalid(let message): message
    case .missing: "No configuration exists yet. Run Setup from the menu bar."
    }
  }
}

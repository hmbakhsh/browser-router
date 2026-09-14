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

  static func normalizeHost(_ host: String) -> String {
    host.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func validate(index: Int) throws {
    let normalizedHost = Self.normalizeHost(host)
    let labels = normalizedHost.split(separator: ".", omittingEmptySubsequences: false)
    let validCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
    let validHost =
      !normalizedHost.isEmpty && normalizedHost.utf8.count <= 253
      && labels.allSatisfy { label in
        guard !label.isEmpty, label.utf8.count <= 63,
          let first = label.unicodeScalars.first, let last = label.unicodeScalars.last
        else { return false }
        return CharacterSet.alphanumerics.contains(first)
          && CharacterSet.alphanumerics.contains(last)
          && label.unicodeScalars.allSatisfy { validCharacters.contains($0) }
      }
    guard validHost else {
      throw ConfigError.invalid("rules[\(index)].match.host is not a valid hostname")
    }

    if let pathPrefix,
      !pathPrefix.hasPrefix("/") || pathPrefix.contains("?") || pathPrefix.contains("#")
    {
      throw ConfigError.invalid(
        "rules[\(index)].match.pathPrefix must be a path beginning with /")
    }
  }
}

enum ConfigError: LocalizedError, Equatable {
  case invalid(String)
  case missing

  var errorDescription: String? {
    switch self {
    case .invalid(let message): message
    case .missing: "No configuration exists yet. Choose Open Configuration from the menu bar."
    }
  }
}

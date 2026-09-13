import Foundation

enum SetupRules {
  static func parse(_ text: String, profile: String) throws -> [RoutingRule] {
    try text.split(whereSeparator: \Character.isNewline).enumerated().compactMap { index, line in
      let raw = line.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !raw.isEmpty, !raw.hasPrefix("#") else { return nil }

      let withoutWildcard = raw.hasPrefix("*.") ? String(raw.dropFirst(2)) : raw
      let value = withoutWildcard.contains("://") ? withoutWildcard : "https://" + withoutWildcard
      guard let components = URLComponents(string: value), let host = components.host else {
        throw ConfigError.invalid("Line \(index + 1) is not a valid domain or URL: \(raw)")
      }

      var path = components.path
      if path.hasSuffix("/**") {
        path.removeLast(3)
      }
      let pathPrefix = path.isEmpty || path == "/" ? nil : path

      return RoutingRule(
        name: raw,
        profile: profile,
        enabled: true,
        match: URLMatch(
          host: host,
          includeSubdomains: raw.hasPrefix("*."),
          pathPrefix: pathPrefix
        )
      )
    }
  }
}

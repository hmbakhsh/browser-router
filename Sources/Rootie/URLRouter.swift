import Foundation

struct RouteDecision: Equatable {
  let profile: String
  let ruleName: String?
}

struct URLRouter {
  let config: RouterConfig

  func route(_ url: URL) -> RouteDecision {
    guard let host = url.host?.lowercased() else {
      return RouteDecision(profile: config.defaultProfile, ruleName: nil)
    }

    for rule in config.rules where rule.enabled {
      if matches(url: url, host: host, matcher: rule.match) {
        return RouteDecision(profile: rule.profile, ruleName: rule.name)
      }
    }

    return RouteDecision(profile: config.defaultProfile, ruleName: nil)
  }

  private func matches(url: URL, host: String, matcher: URLMatch) -> Bool {
    let expectedHost = URLMatch.normalizeHost(matcher.host)
    let hostMatches =
      host == expectedHost
      || (matcher.includeSubdomains && host.hasSuffix("." + expectedHost))

    guard hostMatches else { return false }
    guard let pathPrefix = matcher.pathPrefix else { return true }

    let path = url.path.isEmpty ? "/" : url.path
    if pathPrefix == "/" { return true }

    let normalizedPrefix =
      pathPrefix.hasSuffix("/")
      ? String(pathPrefix.dropLast())
      : pathPrefix
    return path == normalizedPrefix || path.hasPrefix(normalizedPrefix + "/")
  }
}

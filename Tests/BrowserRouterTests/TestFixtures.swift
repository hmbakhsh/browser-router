@testable import BrowserRouter

enum TestFixtures {
  static let workConfig = RouterConfig(
    defaultProfile: "Personal",
    rules: [
      rule("Google Meet", host: "meet.google.com"),
      rule("36 Labs Dev", host: "36labs.dev", subdomains: true),
      rule("36 Labs AI", host: "36labs.ai", subdomains: true),
      rule("Outer Circle", host: "outercircle.one", subdomains: true),
      rule("TrendLab GitHub", host: "github.com", path: "/TrendLab_video"),
      rule("Sentry", host: "sentry.io", subdomains: true),
      rule("LangSmith", host: "smith.langchain.io"),
      rule("Infisical", host: "infisical.com", subdomains: true),
      rule("Railway", host: "railway.com", subdomains: true),
      rule("PlanetScale", host: "app.planetscale.com", path: "/haroon-36labs"),
      rule("Blacksmith", host: "app.blacksmith.sh"),
    ])

  private static func rule(
    _ name: String, host: String, subdomains: Bool = false, path: String? = nil
  ) -> RoutingRule {
    RoutingRule(
      name: name,
      profile: "36 Labs",
      enabled: true,
      match: URLMatch(host: host, includeSubdomains: subdomains, pathPrefix: path))
  }
}

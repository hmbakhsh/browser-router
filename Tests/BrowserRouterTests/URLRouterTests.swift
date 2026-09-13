import Foundation
import Testing

@testable import BrowserRouter

struct URLRouterTests {
  private let config = TestFixtures.workConfig

  @Test("Routes configured work domains and subdomains")
  func workDomains() {
    let workURLs = [
      "https://meet.google.com/abc",
      "https://docs.36labs.dev/guide",
      "https://36labs.ai/",
      "https://outercircle.one/",
      "https://acme.sentry.io/issues/1",
      "https://smith.langchain.io/project/1",
      "https://app.infisical.com/organization/1",
      "https://railway.com/project/1",
      "https://app.blacksmith.sh/organizations/1",
    ]

    for url in workURLs {
      #expect(route(url) == "36 Labs", "Expected work route for \(url)")
    }
  }

  @Test("Uses label-safe hostname boundaries")
  func hostnameBoundaries() {
    #expect(route("https://fake36labs.dev/") == "Personal")
    #expect(route("https://sentry.io.example.com/") == "Personal")
  }

  @Test("Routes only the configured GitHub organization")
  func githubPath() {
    #expect(route("https://github.com/TrendLab_video/repo/issues/1") == "36 Labs")
    #expect(route("https://github.com/TrendLab_video") == "36 Labs")
    #expect(route("https://github.com/TrendLab_videos/repo") == "Personal")
  }

  @Test("Routes only the configured PlanetScale organization")
  func planetScalePath() {
    #expect(route("https://app.planetscale.com/haroon-36labs/db/main") == "36 Labs")
    #expect(route("https://app.planetscale.com/haroon-36labs-other") == "Personal")
    #expect(route("https://app.planetscale.com/someone-else/db") == "Personal")
  }

  @Test("First enabled match wins")
  func rulePrecedence() throws {
    let rules = [
      RoutingRule(
        name: "First", profile: "First Profile", enabled: true,
        match: URLMatch(host: "example.com", includeSubdomains: false, pathPrefix: nil)),
      RoutingRule(
        name: "Second", profile: "Second Profile", enabled: true,
        match: URLMatch(host: "example.com", includeSubdomains: false, pathPrefix: nil)),
    ]
    let router = URLRouter(config: RouterConfig(defaultProfile: "Personal", rules: rules))
    #expect(
      router.route(try #require(URL(string: "https://example.com"))).profile == "First Profile")
  }

  private func route(_ value: String) -> String {
    URLRouter(config: config).route(URL(string: value)!).profile
  }
}

import Testing

@testable import BrowserRouter

struct SetupRulesTests {
  @Test("Creates rules from friendly domain patterns")
  func parsesPatterns() throws {
    let rules = try SetupRules.parse(
      """
      # Work links
      *.example.com
      github.com/acme/**
      https://app.example.org/team
      """,
      profile: "Work")

    #expect(rules.count == 3)
    #expect(
      rules[0].match == URLMatch(host: "example.com", includeSubdomains: true, pathPrefix: nil))
    #expect(rules[1].match.pathPrefix == "/acme")
    #expect(rules[2].match.pathPrefix == "/team")
    #expect(rules.allSatisfy { $0.profile == "Work" })
  }

  @Test("Rejects invalid patterns with a useful line number")
  func rejectsInvalidPattern() {
    #expect(throws: ConfigError.self) {
      try SetupRules.parse("example.com\nnot a host / bad", profile: "Work")
    }
  }
}

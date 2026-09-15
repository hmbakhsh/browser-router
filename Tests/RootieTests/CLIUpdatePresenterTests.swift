import Testing

@testable import Rootie

struct CLIUpdatePresenterTests {
  @Test("Available update shows versions and notes before confirmation")
  func confirmsUpdate() {
    var output: [String] = []
    let presenter = CLIUpdatePresenter(
      readInput: { "y" },
      output: { output.append($0) })

    let accepted = presenter.confirm(
      installedVersion: "0.4.0",
      latestVersion: "0.5.0",
      releaseNotes: "## Fixed\n\n- Safer routing")

    #expect(accepted)
    #expect(
      output == [
        "Installed: 0.4.0",
        "Latest: 0.5.0",
        "",
        "## Fixed\n\n- Safer routing",
        "",
        "Install update? [y/N]",
      ])
  }

  @Test("Only an explicit affirmative response installs")
  func declinesUpdate() {
    for input in [nil, "", "n", "sure"] as [String?] {
      let presenter = CLIUpdatePresenter(readInput: { input }, output: { _ in })
      #expect(
        !presenter.confirm(
          installedVersion: "0.4.0", latestVersion: "0.5.0", releaseNotes: "Notes"))
    }

    let presenter = CLIUpdatePresenter(readInput: { "Y " }, output: { _ in })
    #expect(
      presenter.confirm(
        installedVersion: "0.4.0", latestVersion: "0.5.0", releaseNotes: "Notes"))

    let yesPresenter = CLIUpdatePresenter(readInput: { "YES" }, output: { _ in })
    #expect(
      yesPresenter.confirm(
        installedVersion: "0.4.0", latestVersion: "0.5.0", releaseNotes: "Notes"))
  }

  @Test("Missing release notes have a readable fallback")
  func missingReleaseNotes() {
    var output: [String] = []
    let presenter = CLIUpdatePresenter(readInput: { "n" }, output: { output.append($0) })

    _ = presenter.confirm(
      installedVersion: "0.4.0", latestVersion: "0.5.0", releaseNotes: nil)

    #expect(output.contains("No release notes provided."))
  }
}

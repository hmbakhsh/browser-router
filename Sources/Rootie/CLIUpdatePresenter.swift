import Foundation

struct CLIUpdatePresenter {
  let readInput: () -> String?
  let output: (String) -> Void

  func confirm(
    installedVersion: String,
    latestVersion: String,
    releaseNotes: String?
  ) -> Bool {
    output("Installed: \(installedVersion)")
    output("Latest: \(latestVersion)")
    output("")
    let notes = releaseNotes.flatMap { $0.isEmpty ? nil : $0 } ?? "No release notes provided."
    output(notes)
    output("")
    output("Install update? [y/N]")
    guard let response = readInput()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    else { return false }
    return response == "y" || response == "yes"
  }
}

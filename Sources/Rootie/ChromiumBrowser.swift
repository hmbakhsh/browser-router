import Foundation

struct ChromiumBrowser: Codable, Equatable {
  let name: String
  let applicationPath: String
  let userDataPath: String

  static let helium = ChromiumBrowser(
    name: "Helium",
    applicationPath: "/Applications/Helium.app",
    userDataPath: "~/Library/Application Support/net.imput.helium")

  var applicationURL: URL {
    URL(fileURLWithPath: NSString(string: applicationPath).expandingTildeInPath)
  }

  var userDataURL: URL {
    URL(fileURLWithPath: NSString(string: userDataPath).expandingTildeInPath)
  }
}

enum BrowserCatalog {
  static let known: [ChromiumBrowser] = [
    .helium,
    ChromiumBrowser(
      name: "Google Chrome", applicationPath: "/Applications/Google Chrome.app",
      userDataPath: "~/Library/Application Support/Google/Chrome"),
    ChromiumBrowser(
      name: "Brave Browser", applicationPath: "/Applications/Brave Browser.app",
      userDataPath: "~/Library/Application Support/BraveSoftware/Brave-Browser"),
    ChromiumBrowser(
      name: "Microsoft Edge", applicationPath: "/Applications/Microsoft Edge.app",
      userDataPath: "~/Library/Application Support/Microsoft Edge"),
    ChromiumBrowser(
      name: "Chromium", applicationPath: "/Applications/Chromium.app",
      userDataPath: "~/Library/Application Support/Chromium"),
    ChromiumBrowser(
      name: "Vivaldi", applicationPath: "/Applications/Vivaldi.app",
      userDataPath: "~/Library/Application Support/Vivaldi"),
  ]

  static func installed(fileManager: FileManager = .default) -> [ChromiumBrowser] {
    known.filter {
      fileManager.fileExists(atPath: $0.applicationURL.path)
        && fileManager.fileExists(atPath: $0.userDataURL.appendingPathComponent("Local State").path)
    }
  }
}

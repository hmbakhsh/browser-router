import Foundation

struct ChromiumLauncher {
  let browser: ChromiumBrowser

  func open(_ url: URL, profileDirectory: String) throws {
    guard
      let executableName = Bundle(url: browser.applicationURL)?
        .object(forInfoDictionaryKey: "CFBundleExecutable") as? String
    else {
      throw ChromiumError.appNotFound(browser.applicationURL.path)
    }

    let executableURL = browser.applicationURL
      .appendingPathComponent("Contents/MacOS")
      .appendingPathComponent(executableName)
    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
      throw ChromiumError.appNotFound(browser.applicationURL.path)
    }

    let process = Process()
    process.executableURL = executableURL
    process.arguments = ["--profile-directory=\(profileDirectory)", url.absoluteString]

    do {
      try process.run()
    } catch {
      throw ChromiumError.launchFailed(error.localizedDescription)
    }
  }
}

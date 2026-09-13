import Foundation

struct ChromiumProfile: Equatable {
  let displayName: String
  let directory: String
}

struct ChromiumProfiles {
  let localStateURL: URL

  init(browser: ChromiumBrowser) {
    localStateURL = browser.userDataURL.appendingPathComponent("Local State")
  }

  init(localStateURL: URL) {
    self.localStateURL = localStateURL
  }

  func directory(forDisplayName displayName: String) throws -> String {
    guard let profile = try all().first(where: { $0.displayName == displayName }) else {
      throw ChromiumError.profileNotFound(displayName)
    }
    return profile.directory
  }

  func all() throws -> [ChromiumProfile] {
    let data = try Data(contentsOf: localStateURL)
    let object = try JSONSerialization.jsonObject(with: data)

    guard let root = object as? [String: Any],
      let profile = root["profile"] as? [String: Any],
      let infoCache = profile["info_cache"] as? [String: Any]
    else {
      throw ChromiumError.invalidLocalState
    }

    return infoCache.compactMap { directory, value in
      guard let details = value as? [String: Any], let name = details["name"] as? String else {
        return nil
      }
      return ChromiumProfile(displayName: name, directory: directory)
    }
    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
  }
}

enum ChromiumError: LocalizedError {
  case appNotFound(String)
  case invalidLocalState
  case profileNotFound(String)
  case launchFailed(String)

  var errorDescription: String? {
    switch self {
    case .appNotFound(let path):
      "No Chromium browser was found at \(path)."
    case .invalidLocalState:
      "The browser’s profile data could not be read. Open the browser once and try again."
    case .profileNotFound(let name):
      "No browser profile named “\(name)” was found."
    case .launchFailed(let detail):
      "The browser could not open the link: \(detail)"
    }
  }
}

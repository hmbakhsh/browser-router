import Foundation

enum StarterConfiguration {
  static func make(
    browsers: [ChromiumBrowser] = BrowserCatalog.installed(),
    profiles: (ChromiumBrowser) throws -> [ChromiumProfile] = {
      try ChromiumProfiles(browser: $0).all()
    }
  ) throws -> RouterConfig {
    guard let browser = browsers.first else {
      throw ConfigError.invalid(
        "No supported Chromium browser was found. Install and open one, then try again.")
    }
    let availableProfiles = try profiles(browser)
    guard let profile = preferredProfile(in: availableProfiles) else {
      throw ConfigError.invalid(
        "No profiles were found for \(browser.name). Open the browser once, then try again.")
    }

    return RouterConfig(browser: browser, defaultProfile: profile.displayName, rules: [])
  }

  static func preferredProfile(in profiles: [ChromiumProfile]) -> ChromiumProfile? {
    profiles.first(where: {
      $0.displayName.localizedCaseInsensitiveContains("personal")
    }) ?? profiles.first
  }
}

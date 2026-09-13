import AppKit

struct DefaultBrowserSetter {
  typealias SetHandler = (URL, String, @escaping (Error?) -> Void) -> Void

  private let setHandler: SetHandler

  init(
    setHandler: @escaping SetHandler = { appURL, scheme, completion in
      NSWorkspace.shared.setDefaultApplication(
        at: appURL,
        toOpenURLsWithScheme: scheme,
        completion: completion)
    }
  ) {
    self.setHandler = setHandler
  }

  func makeDefault(appURL: URL, completion: @escaping (Error?) -> Void) {
    // macOS treats the HTTP selection as the default browser choice and updates
    // HTTPS at the same time. A second HTTPS request can fail with permErr.
    setHandler(appURL, "http", completion)
  }
}

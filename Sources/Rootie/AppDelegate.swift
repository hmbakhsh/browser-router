import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let configStore = ConfigStore()
  private let defaultBrowserSetter = DefaultBrowserSetter()

  private var statusItem: NSStatusItem!
  private var statusMenuItem: NSMenuItem!
  private var lastResult = "Starting…"

  func applicationDidFinishLaunching(_ notification: Notification) {
    buildMenu()
    if configStore.load() {
      updateStatus("Ready")
    } else if configStore.error as? ConfigError == .missing {
      createStarterConfiguration()
    } else {
      showError(title: "Could not load configuration", error: configStore.error)
    }
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.scheme == "http" || url.scheme == "https" {
      route(url)
    }
  }

  private func route(_ url: URL) {
    if configStore.config == nil {
      configStore.load()
    }
    guard let config = configStore.config else {
      showError(title: "Routing configuration is invalid", error: configStore.error)
      return
    }

    let decision = URLRouter(config: config).route(url)
    do {
      let browser = config.selectedBrowser
      let directory = try ChromiumProfiles(browser: browser).directory(
        forDisplayName: decision.profile)
      try ChromiumLauncher(browser: browser).open(url, profileDirectory: directory)
      let reason = decision.ruleName.map { " via \($0)" } ?? " (default)"
      updateStatus("Opened in \(decision.profile)\(reason)")
    } catch {
      showError(title: "Could not route link", error: error)
    }
  }

  private func buildMenu() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(
      systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "Rootie")

    let menu = NSMenu()
    statusMenuItem = NSMenuItem(title: lastResult, action: nil, keyEquivalent: "")
    statusMenuItem.isEnabled = false
    menu.addItem(statusMenuItem)
    menu.addItem(.separator())
    menu.addItem(
      withTitle: "Open Configuration", action: #selector(openConfiguration), keyEquivalent: ",")
    menu.addItem(
      withTitle: "Reload Configuration", action: #selector(reloadConfiguration), keyEquivalent: "r")
    menu.addItem(
      withTitle: "Make Default Browser", action: #selector(makeDefaultBrowser), keyEquivalent: "")
    menu.addItem(
      withTitle: "Troubleshooting", action: #selector(showTroubleshooting), keyEquivalent: "")
    menu.addItem(.separator())
    let quitItem = menu.addItem(
      withTitle: "Quit Rootie", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    quitItem.target = NSApp

    for item in menu.items where item.action != nil && item !== quitItem {
      item.target = self
    }
    statusItem.menu = menu
  }

  @objc private func openConfiguration() {
    if !FileManager.default.fileExists(atPath: configStore.configURL.path) {
      createStarterConfiguration()
      return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = ["-t", configStore.configURL.path]
    do {
      try process.run()
    } catch {
      showError(title: "Could not open configuration", error: error)
    }
  }

  @objc private func reloadConfiguration() {
    reloadConfig(showSuccess: true)
  }

  private func reloadConfig(showSuccess: Bool) {
    if configStore.load() {
      updateStatus("Ready")
      if showSuccess {
        showMessage(title: "Configuration loaded", text: configStore.configURL.path)
      }
    } else {
      updateStatus("Configuration error")
      showError(title: "Could not load configuration", error: configStore.error)
    }
  }

  private func createStarterConfiguration() {
    do {
      try configStore.save(StarterConfiguration.make())
      updateStatus("Edit configuration")
      openConfiguration()
    } catch {
      showError(title: "Could not create configuration", error: error)
    }
  }

  @objc private func makeDefaultBrowser() {
    let appURL = Bundle.main.bundleURL
    defaultBrowserSetter.makeDefault(appURL: appURL) { [weak self] error in
      Task { @MainActor in
        if let error {
          self?.showError(title: "Could not set default browser", error: error)
        } else {
          self?.updateStatus("Default browser")
          self?.showMessage(
            title: "Rootie is ready",
            text: "HTTP and HTTPS links will now be routed to your configured browser.")
        }
      }
    }
  }

  @objc private func showTroubleshooting() {
    let profileState =
      configStore.config.map {
        ChromiumProfiles(browser: $0.selectedBrowser).localStateURL.path
      } ?? "Not configured"
    showMessage(
      title: "Rootie",
      text:
        "Status: \(lastResult)\n\nConfiguration:\n\(configStore.configURL.path)\n\nBrowser profiles:\n\(profileState)"
    )
  }

  private func updateStatus(_ status: String) {
    lastResult = status
    statusMenuItem?.title = status
  }

  private func showError(title: String, error: Error?) {
    let detail = error?.localizedDescription ?? "Unknown error"
    updateStatus("Error: \(detail)")
    showMessage(title: title, text: detail, style: .critical)
  }

  private func showMessage(title: String, text: String, style: NSAlert.Style = .informational) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.alertStyle = style
    alert.messageText = title
    alert.informativeText = text
    alert.runModal()
  }
}

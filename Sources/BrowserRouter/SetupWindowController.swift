import AppKit

@MainActor
final class SetupWindowController: NSWindowController {
  private let browserPopup = NSPopUpButton()
  private let defaultProfile = NSPopUpButton()
  private let routedProfile = NSPopUpButton()
  private let rulesTextView = NSTextView()
  private let errorLabel = NSTextField(labelWithString: "")
  private var onSave: ((RouterConfig) throws -> Void)?
  private var browsers: [ChromiumBrowser] = []

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 600),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false)
    window.title = "Set up Browser Router"
    window.center()
    self.init(window: window)
    buildContent()
  }

  func show(
    browsers: [ChromiumBrowser],
    config: RouterConfig?,
    onSave: @escaping (RouterConfig) throws -> Void
  ) {
    self.onSave = onSave
    self.browsers = browsers
    browserPopup.removeAllItems()
    browserPopup.addItems(withTitles: browsers.map(\.name))
    if let configuredBrowser = config?.selectedBrowser,
      let index = browsers.firstIndex(where: {
        $0.applicationPath == configuredBrowser.applicationPath
      })
    {
      browserPopup.selectItem(at: index)
    }
    refreshProfiles(config: config)
    rulesTextView.string = config?.rules.map(pattern).joined(separator: "\n") ?? ""
    rulesTextView.textStorage?.setAttributes(
      [
        .foregroundColor: NSColor.textColor,
        .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
      ],
      range: NSRange(location: 0, length: rulesTextView.string.utf16.count))
    errorLabel.stringValue = ""

    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func buildContent() {
    guard let contentView = window?.contentView else { return }

    let title = NSTextField(labelWithString: "Route links to the right browser profile")
    title.font = .systemFont(ofSize: 22, weight: .semibold)

    let description = wrappingLabel(
      "Choose a default profile, then list the work domains that should use another profile. You can edit the generated JSON at any time."
    )
    description.textColor = .secondaryLabelColor

    let defaultLabel = NSTextField(labelWithString: "Default profile")
    defaultLabel.font = .systemFont(ofSize: 13, weight: .medium)
    let routedLabel = NSTextField(labelWithString: "Profile for matching links")
    routedLabel.font = .systemFont(ofSize: 13, weight: .medium)
    let rulesLabel = NSTextField(labelWithString: "Matching domains and URLs")
    rulesLabel.font = .systemFont(ofSize: 13, weight: .medium)

    let browserLabel = NSTextField(labelWithString: "Chromium browser")
    browserLabel.font = .systemFont(ofSize: 13, weight: .medium)

    let hint = wrappingLabel(
      "One per line. Use *.example.com for an apex domain and its subdomains, or github.com/acme/** for a path prefix."
    )
    hint.textColor = .secondaryLabelColor
    hint.font = .systemFont(ofSize: 12)

    browserPopup.controlSize = .large
    browserPopup.target = self
    browserPopup.action = #selector(browserChanged)
    defaultProfile.controlSize = .large
    routedProfile.controlSize = .large

    rulesTextView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    rulesTextView.textColor = .textColor
    rulesTextView.backgroundColor = .textBackgroundColor
    rulesTextView.isRichText = false
    rulesTextView.isAutomaticQuoteSubstitutionEnabled = false
    rulesTextView.isAutomaticDashSubstitutionEnabled = false
    rulesTextView.textContainerInset = NSSize(width: 8, height: 8)
    rulesTextView.minSize = NSSize(width: 0, height: 170)
    rulesTextView.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    rulesTextView.isVerticallyResizable = true
    rulesTextView.isHorizontallyResizable = false
    rulesTextView.autoresizingMask = [.width]
    rulesTextView.textContainer?.widthTracksTextView = true
    rulesTextView.textContainer?.containerSize = NSSize(
      width: 0, height: CGFloat.greatestFiniteMagnitude)
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .bezelBorder
    scrollView.documentView = rulesTextView
    scrollView.heightAnchor.constraint(equalToConstant: 170).isActive = true

    errorLabel.textColor = .systemRed
    errorLabel.maximumNumberOfLines = 2
    errorLabel.lineBreakMode = .byWordWrapping

    let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
    cancelButton.bezelStyle = .rounded
    let saveButton = NSButton(
      title: "Save and make default", target: self, action: #selector(save))
    saveButton.bezelStyle = .rounded
    saveButton.bezelColor = .controlAccentColor
    saveButton.keyEquivalent = "\r"
    let buttonSpacer = NSView()
    buttonSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    let buttons = NSStackView(views: [buttonSpacer, cancelButton, saveButton])
    buttons.orientation = .horizontal
    buttons.spacing = 8
    buttons.alignment = .centerY

    let stack = NSStackView(views: [
      title, description, browserLabel, browserPopup, defaultLabel, defaultProfile, routedLabel,
      routedProfile, rulesLabel, hint, scrollView, errorLabel, buttons,
    ])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 10
    stack.setCustomSpacing(18, after: description)
    stack.setCustomSpacing(16, after: browserPopup)
    stack.setCustomSpacing(16, after: defaultProfile)
    stack.setCustomSpacing(16, after: routedProfile)
    stack.setCustomSpacing(16, after: scrollView)

    for view in [description, browserPopup, defaultProfile, routedProfile, scrollView, errorLabel] {
      view.translatesAutoresizingMaskIntoConstraints = false
      view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }
    buttons.translatesAutoresizingMaskIntoConstraints = false
    buttons.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

    contentView.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -22),
    ])
  }

  @objc private func browserChanged() {
    refreshProfiles(config: nil)
  }

  private func refreshProfiles(config: RouterConfig?) {
    defaultProfile.removeAllItems()
    routedProfile.removeAllItems()
    guard browserPopup.indexOfSelectedItem >= 0 else { return }

    do {
      let names = try ChromiumProfiles(browser: browsers[browserPopup.indexOfSelectedItem]).all()
        .map(\.displayName)
      defaultProfile.addItems(withTitles: names)
      routedProfile.addItems(withTitles: names)
      select(config?.defaultProfile ?? preferredDefault(in: names), in: defaultProfile)
      select(config?.rules.first?.profile ?? preferredRouted(in: names), in: routedProfile)
      errorLabel.stringValue = ""
    } catch {
      errorLabel.stringValue = error.localizedDescription
    }
  }

  private func wrappingLabel(_ text: String) -> NSTextField {
    let label = NSTextField(wrappingLabelWithString: text)
    label.maximumNumberOfLines = 0
    return label
  }

  private func preferredDefault(in names: [String]) -> String? {
    names.first(where: { $0.localizedCaseInsensitiveContains("personal") }) ?? names.first
  }

  private func preferredRouted(in names: [String]) -> String? {
    names.first(where: {
      $0.localizedCaseInsensitiveContains("work") || $0.localizedCaseInsensitiveContains("36 labs")
    }) ?? names.dropFirst().first ?? names.first
  }

  private func select(_ name: String?, in popup: NSPopUpButton) {
    if let name, popup.itemTitles.contains(name) {
      popup.selectItem(withTitle: name)
    }
  }

  private func pattern(for rule: RoutingRule) -> String {
    let host = rule.match.includeSubdomains ? "*.\(rule.match.host)" : rule.match.host
    guard let path = rule.match.pathPrefix else { return host }
    return host + path + "/**"
  }

  @objc private func cancel() {
    close()
  }

  @objc private func save() {
    guard let defaultName = defaultProfile.titleOfSelectedItem,
      let routedName = routedProfile.titleOfSelectedItem
    else {
      errorLabel.stringValue = "Open the browser and create at least one profile, then try again."
      return
    }

    do {
      let rules = try SetupRules.parse(rulesTextView.string, profile: routedName)
      let browser = browsers[browserPopup.indexOfSelectedItem]
      try onSave?(RouterConfig(browser: browser, defaultProfile: defaultName, rules: rules))
      close()
    } catch {
      errorLabel.stringValue = error.localizedDescription
    }
  }
}

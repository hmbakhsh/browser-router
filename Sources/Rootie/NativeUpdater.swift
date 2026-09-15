import AppKit
import Sparkle

@MainActor
final class NativeUpdater {
  let controller: SPUStandardUpdaterController

  init() {
    controller = SPUStandardUpdaterController(
      startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
  }

  func start() {
    controller.startUpdater()
  }

  func menuItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: "Check for Updates…",
      action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
      keyEquivalent: "")
    item.target = controller
    return item
  }
}

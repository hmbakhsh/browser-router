import Sparkle
import Testing

@testable import Rootie

@MainActor
struct NativeUpdaterTests {
  @Test("Creates a native Sparkle update menu item")
  func menuItem() {
    let updater = NativeUpdater()
    let item = updater.menuItem()

    #expect(item.title == "Check for Updates…")
    #expect(item.target === updater.controller)
    #expect(item.action == #selector(SPUStandardUpdaterController.checkForUpdates(_:)))
  }
}

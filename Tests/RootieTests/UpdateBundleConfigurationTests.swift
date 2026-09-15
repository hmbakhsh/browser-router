import Foundation
import Testing

struct UpdateBundleConfigurationTests {
  @Test("Bundle config uses the signed user-initiated Sparkle feed")
  func sparkleConfiguration() throws {
    let plistURL = repositoryRoot.appendingPathComponent("Resources/Info.plist")
    let data = try Data(contentsOf: plistURL)
    let plist = try #require(
      PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])

    #expect(
      plist["SUFeedURL"] as? String
        == "https://github.com/hmbakhsh/rootie/releases/latest/download/appcast.xml")
    #expect(plist["SUPublicEDKey"] as? String == "7e38BHArNTB69QPfvFxx4CqbDDSgiv+nPi6lgZIEJrQ=")
    #expect(plist["SUEnableAutomaticChecks"] as? Bool == false)
    #expect(plist["SUAutomaticallyUpdate"] as? Bool == false)
    #expect(plist["SUAllowsAutomaticUpdates"] as? Bool == false)
    #expect(plist["SUEnableInstallerLauncherService"] == nil)
    #expect(plist["SUVerifyUpdateBeforeExtraction"] as? Bool == true)
    #expect(plist["SURequireSignedFeed"] as? Bool == true)
    #expect(plist["SUSignedFeedFailureExpirationInterval"] as? Int == 0)
  }

  private var repositoryRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }
}

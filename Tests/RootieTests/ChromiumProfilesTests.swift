import Foundation
import Testing

@testable import Rootie

struct ChromiumProfilesTests {
  @Test("Resolves display names to Chromium profile directories")
  func resolvesProfile() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("Local State")
    let json =
      #"{"profile":{"info_cache":{"Default":{"name":"Personal"},"Profile 3":{"name":"Work"}}}}"#
    try Data(json.utf8).write(to: url)
    let profiles = ChromiumProfiles(localStateURL: url)

    #expect(try profiles.directory(forDisplayName: "Personal") == "Default")
    #expect(try profiles.directory(forDisplayName: "Work") == "Profile 3")
    #expect(try profiles.all().map(\.displayName) == ["Personal", "Work"])
    #expect(throws: ChromiumError.self) {
      try profiles.directory(forDisplayName: "Missing")
    }
  }
}

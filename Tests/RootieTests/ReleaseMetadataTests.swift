import Foundation
import Testing

struct ReleaseMetadataTests {
  @Test("Release workflow signs and publishes the Sparkle feed")
  func releaseWorkflow() throws {
    let workflow = try contents(".github/workflows/release.yml")
    let packageScript = try contents("scripts/package-release.sh")
    let verificationScript = try contents("scripts/verify-release.sh")

    #expect(!workflow.contains("apple-actions/import-codesign-certs"))
    #expect(workflow.contains("SPARKLE_PRIVATE_KEY"))
    #expect(workflow.contains("dist/release/Rootie.zip"))
    #expect(workflow.contains("dist/release/appcast.xml"))
    #expect(!packageScript.contains("notarytool"))
    #expect(packageScript.contains("generate_appcast"))
    #expect(packageScript.contains("--account io.github.hmbakhsh.rootie"))
    #expect(packageScript.contains("--embed-release-notes"))
    #expect(verificationScript.contains("codesign --verify --deep --strict"))
    #expect(!verificationScript.contains("spctl --assess"))
    #expect(verificationScript.contains("-verify_arch arm64 x86_64"))
    #expect(verificationScript.contains("sparkle:edSignature="))
    #expect(verificationScript.contains("sign_update"))
    #expect(verificationScript.contains("--verify \"$APPCAST\""))
    #expect(verificationScript.contains("stat -f%z"))
  }

  private func contents(_ path: String) throws -> String {
    try String(contentsOf: repositoryRoot.appendingPathComponent(path), encoding: .utf8)
  }

  private var repositoryRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }
}

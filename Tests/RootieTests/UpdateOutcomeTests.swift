import Foundation
import Sparkle
import Testing

@testable import Rootie

struct UpdateOutcomeTests {
  @Test("Classifies network, feed, verification, and installation failures")
  func classifiesFailures() {
    #expect(
      UpdateFailure(
        error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
        == .offline)
    #expect(
      UpdateFailure(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse))
        == .invalidFeed)
    #expect(sparkleFailure(.appcastParseError) == .invalidFeed)
    #expect(sparkleFailure(.downloadError) == .invalidFeed)
    #expect(sparkleFailure(.signatureError) == .verificationFailed)
    #expect(sparkleFailure(.validationError) == .verificationFailed)
    #expect(sparkleFailure(.installationError) == .installationFailed)
    #expect(sparkleFailure(.relaunchError) == .installationFailed)
  }

  @Test("Finds a transport failure wrapped by Sparkle")
  func wrappedTransportFailure() {
    let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
    let error = NSError(
      domain: SUSparkleErrorDomain,
      code: Int(SUError.downloadError.rawValue),
      userInfo: [NSUnderlyingErrorKey: underlying])

    #expect(UpdateFailure(error: error) == .offline)
  }

  @Test("Finds a verification failure wrapped by installation")
  func wrappedVerificationFailure() {
    let underlying = NSError(
      domain: SUSparkleErrorDomain, code: Int(SUError.signatureError.rawValue))
    let error = NSError(
      domain: SUSparkleErrorDomain,
      code: Int(SUError.installationError.rawValue),
      userInfo: [NSUnderlyingErrorKey: underlying])

    #expect(UpdateFailure(error: error) == .verificationFailed)
  }

  @Test("Preserves unknown failures as generic updater errors")
  func preservesUnknownFailures() {
    let error = NSError(domain: "example", code: 42)
    #expect(UpdateFailure(error: error) == .other)
  }

  private func sparkleFailure(_ code: SUError) -> UpdateFailure {
    UpdateFailure(error: NSError(domain: SUSparkleErrorDomain, code: Int(code.rawValue)))
  }
}

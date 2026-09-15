import Foundation
import Sparkle

enum UpdateFailure: Equatable {
  case offline
  case invalidFeed
  case verificationFailed
  case installationFailed
  case other

  init(error: NSError) {
    if let urlFailure = Self.urlFailure(in: error) {
      self = urlFailure
      return
    }

    guard error.domain == SUSparkleErrorDomain, let code = SUError(rawValue: Int32(error.code))
    else {
      self = .other
      return
    }

    if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
      let underlyingFailure = UpdateFailure(error: underlying)
      if underlyingFailure != .other {
        self = underlyingFailure
        return
      }
    }

    switch code {
    case .appcastParseError, .appcastError, .invalidFeedURLError, .insecureFeedURLError:
      self = .invalidFeed
    case .downloadError:
      self = .invalidFeed
    case .signatureError, .validationError, .insufficientSigningError, .noPublicDSAFoundError:
      self = .verificationFailed
    case .fileCopyFailure, .authenticationFailure, .missingUpdateError, .missingInstallerToolError,
      .relaunchError, .installationError, .installationCanceledError,
      .installationAuthorizeLaterError, .notValidUpdateError, .agentInvalidationError,
      .installationWriteNoPermissionError:
      self = .installationFailed
    default:
      self = .other
    }
  }

  private static func urlFailure(in error: NSError) -> UpdateFailure? {
    if error.domain == NSURLErrorDomain {
      switch error.code {
      case NSURLErrorBadServerResponse, NSURLErrorFileDoesNotExist,
        NSURLErrorResourceUnavailable:
        return .invalidFeed
      default:
        return .offline
      }
    }

    guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError else { return nil }
    return urlFailure(in: underlying)
  }
}

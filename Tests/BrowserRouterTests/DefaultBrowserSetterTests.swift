import Foundation
import Testing

@testable import BrowserRouter

struct DefaultBrowserSetterTests {
  @Test("Requests the HTTP handler once because macOS updates both web schemes")
  func setsWebHandlerOnce() async {
    final class Recorder: @unchecked Sendable {
      var schemes: [String] = []
    }
    let recorder = Recorder()
    let setter = DefaultBrowserSetter { _, scheme, completion in
      recorder.schemes.append(scheme)
      completion(nil)
    }

    await withCheckedContinuation { continuation in
      setter.makeDefault(appURL: URL(fileURLWithPath: "/Example.app")) { error in
        #expect(error == nil)
        continuation.resume()
      }
    }

    #expect(recorder.schemes == ["http"])
  }
}

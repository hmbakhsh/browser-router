import AppKit

@main
@MainActor
enum BrowserRouterApp {
  static func main() {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if BrowserRouterCLI.shouldRun(
      arguments: arguments, executablePath: CommandLine.arguments[0])
    {
      exit(BrowserRouterCLI(arguments: arguments).run())
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
  }
}

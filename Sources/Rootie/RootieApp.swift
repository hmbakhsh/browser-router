import AppKit

@main
@MainActor
enum RootieApp {
  static func main() {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if RootieCLI.shouldRun(
      arguments: arguments, executablePath: CommandLine.arguments[0])
    {
      exit(RootieCLI(arguments: arguments).run())
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
  }
}

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BrowserRouter",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BrowserRouter", targets: ["BrowserRouter"])
    ],
    targets: [
        .executableTarget(name: "BrowserRouter"),
        .testTarget(name: "BrowserRouterTests", dependencies: ["BrowserRouter"])
    ],
    swiftLanguageModes: [.v5]
)

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Rootie",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Rootie", targets: ["Rootie"])
    ],
    targets: [
        .executableTarget(name: "Rootie"),
        .testTarget(name: "RootieTests", dependencies: ["Rootie"])
    ],
    swiftLanguageModes: [.v5]
)

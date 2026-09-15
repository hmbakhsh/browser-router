// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Rootie",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Rootie", targets: ["Rootie"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Rootie",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks",
                ])
            ]),
        .testTarget(name: "RootieTests", dependencies: ["Rootie"])
    ],
    swiftLanguageModes: [.v5]
)

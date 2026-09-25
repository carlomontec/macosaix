// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSaiXModern",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MacOSaiXKit",
            targets: ["MacOSaiXKit"]
        ),
        .executable(
            name: "macosaix-cli",
            targets: ["macosaix-cli"]
        ),
        .executable(
            name: "MacOSaiXApp",
            targets: ["MacOSaiXApp"]
        )
    ],
    targets: [
        .target(
            name: "MacOSaiXKit",
            dependencies: [],
            path: "Sources/MacOSaiXKit"
        ),
        .executableTarget(
            name: "macosaix-cli",
            dependencies: ["MacOSaiXKit"],
            path: "Sources/macosaix-cli"
        ),
        .executableTarget(
            name: "MacOSaiXApp",
            dependencies: ["MacOSaiXKit"],
            path: "Sources/MacOSaiXApp"
        )
    ],
    swiftLanguageModes: [.v5]
)

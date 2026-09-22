// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSaiXModern",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacOSaiXCore",
            targets: ["MacOSaiXCore"]
        ),
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
            name: "MacOSaiXCore",
            path: "Sources/MacOSaiXCore",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "MacOSaiXKit",
            dependencies: ["MacOSaiXCore"],
            path: "Sources/MacOSaiXKit"
        ),
        .executableTarget(
            name: "macosaix-cli",
            dependencies: ["MacOSaiXCore", "MacOSaiXKit"],
            path: "Sources/macosaix-cli"
        ),
        .executableTarget(
            name: "MacOSaiXApp",
            dependencies: ["MacOSaiXCore", "MacOSaiXKit"],
            path: "Sources/MacOSaiXApp"
        )
    ],
    swiftLanguageModes: [.v5]
)

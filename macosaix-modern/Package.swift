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
        .executable(
            name: "macosaix-cli",
            targets: ["macosaix-cli"]
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
        .executableTarget(
            name: "macosaix-cli",
            dependencies: ["MacOSaiXCore"],
            path: "Sources/macosaix-cli"
        )
    ]
)

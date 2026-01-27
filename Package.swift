// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BedtimeNag",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BedtimeNag",
            dependencies: [],
            path: "Sources"
        )
    ]
)

// swift-tools-version: 5.10.1
import PackageDescription

let package = Package(
    name: "backup_daemon",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "backup_daemon",
            targets: ["backup_daemon"]),
    ],
    dependencies: [
        // Add any dependencies here.
    ],
    targets: [
        .executableTarget(
            name: "backup_daemon",
            dependencies: []
        )
    ]
)

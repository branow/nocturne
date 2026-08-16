// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "nocturne",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(name: "nocturne", path: "Sources/nocturne")
    ]
)

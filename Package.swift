// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyMapper",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "json2swift", targets: ["json2swift"]),
    ],
    targets: [
        .executableTarget(name: "json2swift")
    ]
)


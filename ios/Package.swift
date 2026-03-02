// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShogunApp",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.1.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ShogunApp",
            dependencies: [
                .product(name: "Citadel", package: "Citadel"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "ShogunApp/"
        ),
        .testTarget(
            name: "ShogunAppTests",
            dependencies: ["ShogunApp"],
            path: "ShogunApp/Tests/"
        ),
    ]
)

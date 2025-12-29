// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MermaidKitten",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        .executable(name: "MermaidGenerator", targets: ["MermaidGenerator"]),
        .plugin(name: "MermaidKitten", targets: ["MermaidKitten"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "MermaidGenerator",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .plugin(
            name: "MermaidKitten",
            capability: .command(
                intent: .documentationGeneration(),
                permissions: []
            ),
            dependencies: [
                .target(name: "MermaidGenerator")
            ]
        ),
    ]
)

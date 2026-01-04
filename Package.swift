// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MermaidKitten",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "MermaidGeneratorCore", targets: ["MermaidGeneratorCore"]),
        .executable(name: "MermaidGenerator", targets: ["MermaidGenerator"]),
        .plugin(name: "MermaidKitten", targets: ["MermaidKitten"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "MermaidGeneratorCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "MermaidGenerator",
            dependencies: [
                "MermaidGeneratorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
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
        .testTarget(
            name: "MermaidGeneratorTests",
            dependencies: [
                "MermaidGeneratorCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)

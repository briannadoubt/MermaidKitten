// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MermaidKitten",
    products: [
        .executable(name: "MermaidGenerator", targets: ["MermaidGenerator"]),
        .plugin(name: "MermaidKitten", targets: ["MermaidKitten"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.30.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.3"),
    ],
    targets: [
        .executableTarget(
            name: "MermaidGenerator",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .plugin(
            name: "MermaidKitten",
            capability: .command(intent: .documentationGeneration()),
            dependencies: [
                .target(name: "MermaidGenerator", condition: .when(platforms: [.macOS]))
            ]
        ),
    ]
)

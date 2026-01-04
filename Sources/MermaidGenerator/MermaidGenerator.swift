//
//  MermaidGenerator.swift
//  MermaidGenerator
//
//  Created by Brianna Zamora on 5/18/23.
//

import Foundation
import MermaidGeneratorCore
import ArgumentParser

@main
struct MermaidGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate Mermaid class diagrams from Swift source code."
    )

    @Argument(help: "Path to the directory containing Swift files.")
    var directory: String

    @Option(name: .shortAndLong, help: "Output file for the mermaid diagram.")
    var output: String?

    @Option(name: .shortAndLong, help: "Title for the diagram.")
    var title: String?

    func run() throws {
        let files = getAllSwiftFiles(path: directory)
        let diagram = try generateDiagram(from: files, title: title ?? "Class Diagram")
        try write(diagram: diagram)
    }

    private func getAllSwiftFiles(path: String) -> [URL] {
        var swiftFiles: [URL] = []
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            print("Failed to get enumerator for directory: \(path)")
            return swiftFiles
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }

    private func write(diagram: String) throws {
        guard let output = output else {
            print(diagram)
            return
        }

        let url = URL(fileURLWithPath: output)
        try diagram.write(to: url, atomically: true, encoding: .utf8)
    }
}

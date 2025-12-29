//
//  MermaidKitten.swift
//  MermaidKitten
//
//  Created by Brianna Zamora on 5/18/23.
//

import PackagePlugin
import Foundation

@main
struct MermaidKitten: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "MermaidGenerator")

        // Default to the package directory if no arguments provided
        let targetDirectory: String
        if arguments.isEmpty {
            targetDirectory = context.package.directory.string
        } else {
            targetDirectory = arguments.first!
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = [targetDirectory]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw MermaidKittenError.generationFailed(code: process.terminationStatus)
        }
    }
}

enum MermaidKittenError: Error, CustomStringConvertible {
    case generationFailed(code: Int32)

    var description: String {
        switch self {
        case .generationFailed(let code):
            return "MermaidGenerator failed with exit code \(code)"
        }
    }
}

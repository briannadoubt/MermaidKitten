//
//  MermaidKitten.swift
//  MermaidKitten
//
//  Created by Brianna Zamora on 5/18/23.
//

import PackagePlugin
import Foundation

@main
struct MermaidKitten: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        return [
            .buildCommand(
                displayName: "MermaidKitten",
                executable: try context.tool(named: "MermaidGenerator").path,
                arguments: ["--directory", "\(target.directory.string)"]
            )
        ]
    }
}

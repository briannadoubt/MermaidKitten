//
//  MermaidGenerator.swift
//  MermaidGenerator
//
//  Created by Brianna Zamora on 5/18/23.
//

import Foundation
import SwiftSyntax
import SwiftParser
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
        let diagram = try generateDiagram(from: files)
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

    private func generateDiagram(from files: [URL]) throws -> String {
        let collector = TypeCollector()

        for fileURL in files {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            let syntax = Parser.parse(source: source)
            collector.walk(syntax)
        }

        return collector.buildDiagram(title: title ?? "Class Diagram")
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

// MARK: - Type Collector

final class TypeCollector: SyntaxVisitor, @unchecked Sendable {
    private(set) var types: [TypeDeclaration] = []
    private(set) var extensions: [ExtensionDeclaration] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeDecl = TypeDeclaration(
            kind: .class,
            name: node.name.text,
            inheritedTypes: extractInheritedTypes(from: node.inheritanceClause),
            members: extractMembers(from: node.memberBlock),
            genericParameters: extractGenericParameters(from: node.genericParameterClause)
        )
        types.append(typeDecl)
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeDecl = TypeDeclaration(
            kind: .struct,
            name: node.name.text,
            inheritedTypes: extractInheritedTypes(from: node.inheritanceClause),
            members: extractMembers(from: node.memberBlock),
            genericParameters: extractGenericParameters(from: node.genericParameterClause)
        )
        types.append(typeDecl)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeDecl = TypeDeclaration(
            kind: .enum,
            name: node.name.text,
            inheritedTypes: extractInheritedTypes(from: node.inheritanceClause),
            members: extractMembers(from: node.memberBlock),
            genericParameters: extractGenericParameters(from: node.genericParameterClause)
        )
        types.append(typeDecl)
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeDecl = TypeDeclaration(
            kind: .protocol,
            name: node.name.text,
            inheritedTypes: extractInheritedTypes(from: node.inheritanceClause),
            members: extractMembers(from: node.memberBlock),
            genericParameters: []
        )
        types.append(typeDecl)
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeDecl = TypeDeclaration(
            kind: .actor,
            name: node.name.text,
            inheritedTypes: extractInheritedTypes(from: node.inheritanceClause),
            members: extractMembers(from: node.memberBlock),
            genericParameters: extractGenericParameters(from: node.genericParameterClause)
        )
        types.append(typeDecl)
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let extDecl = ExtensionDeclaration(
            extendedType: node.extendedType.trimmedDescription,
            inheritedTypes: extractInheritedTypes(from: node.inheritanceClause),
            members: extractMembers(from: node.memberBlock)
        )
        extensions.append(extDecl)
        return .visitChildren
    }

    // MARK: - Extraction Helpers

    private func extractInheritedTypes(from clause: InheritanceClauseSyntax?) -> [String] {
        guard let clause = clause else { return [] }
        return clause.inheritedTypes.map { $0.type.trimmedDescription }
    }

    private func extractGenericParameters(from clause: GenericParameterClauseSyntax?) -> [String] {
        guard let clause = clause else { return [] }
        return clause.parameters.map { $0.name.text }
    }

    private func extractMembers(from memberBlock: MemberBlockSyntax) -> [MemberDeclaration] {
        var members: [MemberDeclaration] = []

        for member in memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                    let typeName = binding.typeAnnotation?.type.trimmedDescription
                    let accessLevel = extractAccessLevel(from: varDecl.modifiers)
                    let isStatic = hasStaticModifier(varDecl.modifiers)

                    members.append(MemberDeclaration(
                        kind: .property,
                        name: identifier.identifier.text,
                        type: typeName,
                        accessLevel: accessLevel,
                        isStatic: isStatic
                    ))
                }
            } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let accessLevel = extractAccessLevel(from: funcDecl.modifiers)
                let isStatic = hasStaticModifier(funcDecl.modifiers)
                let returnType = funcDecl.signature.returnClause?.type.trimmedDescription
                let parameters = funcDecl.signature.parameterClause.parameters.map { param -> String in
                    let name = param.firstName.text
                    let type = param.type.trimmedDescription
                    return "\(name): \(type)"
                }

                members.append(MemberDeclaration(
                    kind: .method,
                    name: "\(funcDecl.name.text)(\(parameters.joined(separator: ", ")))",
                    type: returnType,
                    accessLevel: accessLevel,
                    isStatic: isStatic
                ))
            } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                let accessLevel = extractAccessLevel(from: initDecl.modifiers)
                let parameters = initDecl.signature.parameterClause.parameters.map { param -> String in
                    let name = param.firstName.text
                    let type = param.type.trimmedDescription
                    return "\(name): \(type)"
                }

                members.append(MemberDeclaration(
                    kind: .initializer,
                    name: "init(\(parameters.joined(separator: ", ")))",
                    type: nil,
                    accessLevel: accessLevel,
                    isStatic: false
                ))
            }
        }

        return members
    }

    private func extractAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel {
        for modifier in modifiers {
            switch modifier.name.text {
            case "public": return .public
            case "private": return .private
            case "fileprivate": return .fileprivate
            case "internal": return .internal
            case "open": return .open
            default: continue
            }
        }
        return .internal
    }

    private func hasStaticModifier(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.text == "static" || $0.name.text == "class" }
    }

    // MARK: - Diagram Building

    func buildDiagram(title: String) -> String {
        var lines: [String] = []
        lines.append("---")
        lines.append("title: \(title)")
        lines.append("---")
        lines.append("classDiagram")

        // Collect all known type names for relationship filtering
        let knownTypes = Set(types.map { $0.name })

        // Add type declarations
        for type in types {
            lines.append(contentsOf: type.mermaidLines(knownTypes: knownTypes))
        }

        // Add extension relationships
        for ext in extensions {
            for inherited in ext.inheritedTypes {
                if knownTypes.contains(inherited) || isCommonProtocol(inherited) {
                    lines.append("    \(ext.extendedType) ..|> \(inherited) : conforms")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private func isCommonProtocol(_ name: String) -> Bool {
        let common: Set<String> = [
            "Equatable", "Hashable", "Codable", "Decodable", "Encodable",
            "Comparable", "Identifiable", "Sendable", "CustomStringConvertible",
            "Error", "LocalizedError", "Collection", "Sequence"
        ]
        return common.contains(name)
    }
}

// MARK: - Data Models

enum TypeKind: String, Sendable {
    case `class`
    case `struct`
    case `enum`
    case `protocol`
    case actor
}

enum AccessLevel: String, Sendable {
    case `public` = "+"
    case `internal` = "~"
    case `private` = "-"
    case `fileprivate` = "-"
    case `open` = "+"
}

enum MemberKind: Sendable {
    case property
    case method
    case initializer
}

struct MemberDeclaration: Sendable {
    let kind: MemberKind
    let name: String
    let type: String?
    let accessLevel: AccessLevel
    let isStatic: Bool

    var mermaidLine: String {
        let staticPrefix = isStatic ? "$" : ""
        let typeStr = type.map { " \($0)" } ?? ""
        return "\(accessLevel.rawValue)\(staticPrefix)\(name)\(typeStr)"
    }
}

struct TypeDeclaration: Sendable {
    let kind: TypeKind
    let name: String
    let inheritedTypes: [String]
    let members: [MemberDeclaration]
    let genericParameters: [String]

    func mermaidLines(knownTypes: Set<String>) -> [String] {
        var lines: [String] = []

        // Class definition with stereotype
        let genericStr = genericParameters.isEmpty ? "" : "~\(genericParameters.joined(separator: ", "))~"
        lines.append("    class \(name)\(genericStr) {")

        // Add stereotype annotation
        switch kind {
        case .struct:
            lines.append("        <<struct>>")
        case .enum:
            lines.append("        <<enum>>")
        case .protocol:
            lines.append("        <<protocol>>")
        case .actor:
            lines.append("        <<actor>>")
        case .class:
            break
        }

        // Add members
        for member in members {
            lines.append("        \(member.mermaidLine)")
        }

        lines.append("    }")

        // Add inheritance/conformance relationships
        for inherited in inheritedTypes {
            let relationship: String
            if knownTypes.contains(inherited) {
                relationship = "\(name) --|> \(inherited)"
            } else {
                relationship = "\(name) ..|> \(inherited)"
            }
            lines.append("    \(relationship)")
        }

        return lines
    }
}

struct ExtensionDeclaration: Sendable {
    let extendedType: String
    let inheritedTypes: [String]
    let members: [MemberDeclaration]
}

// MARK: - Mermaid Relationship Operators

// These operators provide a nice DSL for building relationships manually

// MARK: Inheritance
infix operator <|-- : AdditionPrecedence
public func <|-- (lhs: String, rhs: String) -> String {
    "\(lhs) <|-- \(rhs)"
}

infix operator --|> : AdditionPrecedence
public func --|> (lhs: String, rhs: String) -> String {
    "\(lhs) --|> \(rhs)"
}

// MARK: Composition
infix operator *-- : AdditionPrecedence
public func *-- (lhs: String, rhs: String) -> String {
    "\(lhs) *-- \(rhs)"
}

infix operator --* : AdditionPrecedence
public func --* (lhs: String, rhs: String) -> String {
    "\(lhs) --* \(rhs)"
}

// MARK: Aggregation
infix operator o-- : AdditionPrecedence
public func o-- (lhs: String, rhs: String) -> String {
    "\(lhs) o-- \(rhs)"
}

infix operator --o : AdditionPrecedence
public func --o (lhs: String, rhs: String) -> String {
    "\(lhs) --o \(rhs)"
}

// MARK: Association
infix operator --> : AdditionPrecedence
public func --> (lhs: String, rhs: String) -> String {
    "\(lhs) --> \(rhs)"
}

infix operator <-- : AdditionPrecedence
public func <-- (lhs: String, rhs: String) -> String {
    "\(lhs) <-- \(rhs)"
}

// MARK: Dependency (dashed)
infix operator ..> : AdditionPrecedence
public func ..> (lhs: String, rhs: String) -> String {
    "\(lhs) ..> \(rhs)"
}

infix operator <.. : AdditionPrecedence
public func <.. (lhs: String, rhs: String) -> String {
    "\(lhs) <.. \(rhs)"
}

// MARK: Realization (dashed with arrow)
infix operator ..|> : AdditionPrecedence
public func ..|> (lhs: String, rhs: String) -> String {
    "\(lhs) ..|> \(rhs)"
}

infix operator <|.. : AdditionPrecedence
public func <|.. (lhs: String, rhs: String) -> String {
    "\(lhs) <|.. \(rhs)"
}

// MARK: Link (solid)
infix operator --- : AdditionPrecedence
public func --- (lhs: String, rhs: String) -> String {
    "\(lhs) -- \(rhs)"
}

// MARK: Link (dashed)
infix operator .. : AdditionPrecedence
public func .. (lhs: String, rhs: String) -> String {
    "\(lhs) .. \(rhs)"
}

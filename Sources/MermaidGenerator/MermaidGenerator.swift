//
//  MermaidGenerator.swift
//  MermaidGenerator
//
//  Created by Brianna Zamora on 5/18/23.
//

import Foundation
import SourceKittenFramework
import ArgumentParser

typealias Substructure = [SourceDictionary]
typealias SourceDictionary = [String: SourceKitRepresentable]

@main
struct MermaidGenerator: ParsableCommand {
    @Argument(help: "Path to the directory containing Swift files.")
    var directory: String

    @Option(name: .shortAndLong, help: "Output file for the mermaid diagram.")
    var output: String?

    private var factory = ClassDiagramFactory()

    func run() async throws {
        let files = getAllSwiftFiles(path: directory)
        try await parse(files: files)
        try await output(factory.diagram())
    }

    private func getAllSwiftFiles(path: String) -> [File] {
        var swiftFiles = [File]()
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: path) else {
            print("Failed to get enumerator for directory: \(path)")
            return swiftFiles
        }

        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix(".swift") {
                swiftFiles.append(File(path: "\(path)/\(element)")!)
            }
        }

        return swiftFiles
    }

    private func parse(files: [File]) async throws {
        for file in files {
            try await parse(file: file)
        }
    }

    private func parse(file: File) async throws {
        let structure = try Structure(file: file)
        let dictionary = structure.dictionary
        await parse(topLevel: dictionary)
    }

    private func parse(topLevel dictionary: SourceDictionary) async {
        for (rawKey, value) in dictionary {
            guard let key = SwiftDocKey(rawValue: rawKey) else {
                continue
            }
            let diagramNode = parse(key: key, value: value, name: nil)
            await factory.add(node: diagramNode)
        }
    }

    private func parse(enumCases substructure: Substructure, for name: String) -> String {
        var string = ""
        for structure in substructure {
            guard
                let value = structure[SwiftDocKey.kind.rawValue] as? String,
                let kind = SwiftDeclarationKind(rawValue: value),
                kind == .enumcase,
                let enumElement = structure[SwiftDocKey.substructure.rawValue] as? Substructure
            else {
                continue
            }
            for element in enumElement {
                guard let elementName = element[SwiftDocKey.name.rawValue] else {
                    continue
                }
                string.append("\(name) \(element)\n\t")
            }
        }
    }

    private func parse(inheritedTypes substructure: Substructure, for name: String) -> String {
        var string = ""
        for structure in substructure {
            guard let inheritedType = structure[SwiftDocKey.name.rawValue] else {
                continue
            }
            string.append(name <|-- inheritedType)
            string.append("\n\t")
        }
        return string
    }

    private func parse(enum substructure: SourceDictionary, name: String) -> String {
        var string = """
            class `\(name)`
            <<enum>> `\(name)`
        """
        if let inheritedTypes = substructure[SwiftDocKey.inheritedtypes.rawValue] as? Substructure {
            string.append(parse(key: .inheritedtypes, value: inheritedTypes, name: name))
        }
        if let docs = substructure[SwiftDocKey.documentationComment.rawValue] {
            string.append("note for `\(name)` \"\(docs)\"")
        }
        return string
    }

    private func parse(dictionary: SourceDictionary, name: String?) -> String {
        dictionary.map { rawKey, value in
            guard let key = SwiftDocKey(rawValue: rawKey) else {
                return ""
            }
            return parse(key: key, value: value, name: name)
        }
        .joined(separator: "\n\t")
    }

    private func parse(key: SwiftDocKey, value: SourceKitRepresentable, name: String?) -> String {
        switch key {
        case .annotatedDeclaration:
            break
        case .bodyLength:
            break
        case .bodyOffset:
            break
        case .diagnosticStage:
            break
        case .elements:
            break
        case .filePath:
            break
        case .fullXMLDocs:
            break
        case .kind:
            break
        case .length:
            break
        case .name:
            break
        case .nameLength:
            break
        case .nameOffset:
            break
        case .offset:
            break
        case .substructure:
            if let substructure = value as? Substructure {
                return parse(substructure: substructure)
            }
        case .syntaxMap:
            break
        case .typeName:
            return value as? String ?? ""
        case .inheritedtypes:
            if
                let inheritedTypes = value as? Substructure,
                let name
            {
                return parse(inheritedTypes: inheritedTypes, for: name)
            }
        case .docColumn:
            break
        case .documentationComment:
            break
        case .docDeclaration:
            break
        case .docDiscussion:
            break
        case .docFile:
            break
        case .docLine:
            break
        case .docName:
            break
        case .docParameters:
            break
        case .docResultDiscussion:
            break
        case .docType:
            break
        case .usr:
            break
        case .parsedDeclaration:
            break
        case .parsedScopeEnd:
            break
        case .parsedScopeStart:
            break
        case .swiftDeclaration:
            break
        case .swiftName:
            break
        case .alwaysDeprecated:
            break
        case .alwaysUnavailable:
            break
        case .deprecationMessage:
            break
        case .unavailableMessage:
            break
        case .annotations:
            break
        case .attributes:
            break
        case .attribute:
            break
        }
        return ""
    }

    private func parse(substructure: Substructure) -> String {
        for structure in substructure {
            guard
                let rawName = structure[SwiftDocKey.name.rawValue],
                let rawKind = structure[SwiftDocKey.kind.rawValue] as? String,
                let kind = SwiftDeclarationKind(rawValue: rawKind)
            else {
                continue
            }
            let name = "`\(rawName)`"
            switch kind {
            case .associatedtype:
                break
            case .class:
                break
            case .enum:
                return parse(enum: structure, name: name)
            case .enumcase:
                return parse(enumCases: substructure, for: name)
            case .enumelement:
                break
            case .extension:
                break
            case .extensionClass:
                break
            case .extensionEnum:
                break
            case .extensionProtocol:
                break
            case .extensionStruct:
                break
            case .functionAccessorAddress:
                break
            case .functionAccessorDidset:
                break
            case .functionAccessorGetter:
                break
            case .functionAccessorModify:
                break
            case .functionAccessorMutableaddress:
                break
            case .functionAccessorRead:
                break
            case .functionAccessorSetter:
                break
            case .functionAccessorWillset:
                break
            case .functionConstructor:
                break
            case .functionDestructor:
                break
            case .functionFree:
                break
            case .functionMethodClass:
                break
            case .functionMethodInstance:
                break
            case .functionMethodStatic:
                break
            case .functionOperator:
                break
            case .functionOperatorInfix:
                break
            case .functionOperatorPostfix:
                break
            case .functionOperatorPrefix:
                break
            case .functionSubscript:
                break
            case .genericTypeParam:
                break
            case .module:
                break
            case .opaqueType:
                break
            case .precedenceGroup:
                break
            case .protocol:
                break
            case .struct:
                break
            case .typealias:
                break
            case .varClass:
                break
            case .varGlobal:
                break
            case .varInstance:
                break
            case .varLocal:
                break
            case .varParameter:
                break
            case .varStatic:
                break
            }
        }
    }

    private func output(_ graph: String) throws {
        guard let output = output else {
            print(graph)
            return
        }

        let url = URL(fileURLWithPath: output)
        try graph.write(to: url, atomically: true, encoding: String.Encoding.utf8)
    }
}

actor ClassDiagramFactory: Decodable {

    var nodes: [String] = []

    enum CodingKeys: CodingKey {
        case nodes
    }

    @ClassDiagramBuilder func diagram() -> String {
        nodes
    }

    func add(node: String) {
        if !nodes.contains(node) {
            nodes.append(node)
        }
    }
}

@resultBuilder
public struct ClassDiagramBuilder {
    private static func title() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    }

    public static func buildFinalResult(_ component: String) -> String {
        """
        ---
        title: \(title())
        ---
        classDiagram
            \(component)
        """
    }

    public static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }

    public static func buildArray(_ components: [String]) -> String {
        removeDuplicates(array: components)
            .joined(separator: "\n\t")
    }

    public static func buildBlock(_ components: String...) -> String {
        buildArray(components)
    }

    public static func buildBlock(_ components: [String]...) -> String {
        buildArray(components.flatMap({ $0 }))
    }

    private static func removeDuplicates(array: [String]) -> [String] {
        var encountered = Set<String>()
        var result: [String] = []
        for value in array {
            if !encountered.contains(value) {
                encountered.insert(value)
                result.append(value)
            }
        }
        return result
    }
}

// MARK: Inheritence

infix operator <|--
public func <|--<L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " <|-- " + String(describing: rhs)
}

infix operator --|>
public func --|><L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " --|> " + String(describing: rhs)
}

infix operator <|--|>
public func <|--|><L, R>(lhs: L, rhs: R) -> String {
    String(describing: lhs) + " <|--|> " + String(describing: rhs)
}

// MARK: Composition

infix operator *--
public func *--<L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " *-- " + String(describing: rhs))
    """
}

infix operator --*
public func --*<L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " --* " + String(describing: rhs))
    """
}

infix operator *--*
public func *--*<L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " *--* " + String(describing: rhs))
    """
}

// MARK: Aggregation

infix operator •--
public func •--<L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " o-- " + String(describing: rhs))
    """
}

infix operator --•
public func --•<L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " --o " + String(describing: rhs))
    """
}

infix operator •--•
public func •--•<L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " o--o " + String(describing: rhs))
    """
}

// MARK: Association

infix operator -->
func --><L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " --> " + String(describing: rhs)
}

infix operator <--
func <--<L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " <-- " + String(describing: rhs)
}

infix operator <-->
func <--><L, R>(lhs: L, rhs: R) -> String {
    return """
    \(String(describing: lhs) + " <--> " + String(describing: rhs))
    """
}

// MARK: Link (Solid)

infix operator --
func --<L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " -- " + String(describing: rhs)
}

// MARK: Dependency

infix operator <••
func <••<L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " <.. " + String(describing: rhs)
}

infix operator ••>
func ••><L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " ..> " + String(describing: rhs)
}

infix operator <••>
func <••><L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " <..> " + String(describing: rhs)
}

// MARK: Realization

infix operator <|••
func <|••<L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " <|.. " + String(describing: rhs)
}

infix operator ••|>
func ••|><L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " ..|> " + String(describing: rhs)
}

infix operator <|••|>
func <|••|><L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " <|..|> " + String(describing: rhs)
}

// Line (Dashed)
infix operator ••
func ••<L, R>(lhs: L, rhs: R) -> String {
    return String(describing: lhs) + " .. " + String(describing: rhs)
}

@resultBuilder
struct DiagramRelationship {
    static func buildBlock(_ components: DiagramComponent...) -> String {
        components.map(\.string).joined(separator: " ")
    }
}

enum DiagramComponent {
    case relationship(lhs: String, relationship: String, rhs: String)

    var string: String {
        switch self {
        case .relationship(let lhs, let relationship, let rhs):
            return lhs + relationship + rhs
        }
    }
}

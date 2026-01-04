import Testing
import Foundation
@testable import MermaidGenerator

@Suite("MermaidGenerator Tests")
struct MermaidGeneratorTests {

    @Test("TypeCollector extracts class declarations")
    func testClassExtraction() throws {
        let source = """
        class MyClass {
            var name: String
            func doSomething() {}
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.types.first?.name == "MyClass")
        #expect(collector.types.first?.kind == .class)
        #expect(collector.types.first?.members.count == 2)
    }

    @Test("TypeCollector extracts struct declarations")
    func testStructExtraction() throws {
        let source = """
        struct Point {
            var x: Double
            var y: Double
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.types.first?.name == "Point")
        #expect(collector.types.first?.kind == .struct)
    }

    @Test("TypeCollector extracts enum declarations")
    func testEnumExtraction() throws {
        let source = """
        enum Status {
            case active
            case inactive
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.types.first?.name == "Status")
        #expect(collector.types.first?.kind == .enum)
    }

    @Test("TypeCollector extracts protocol declarations")
    func testProtocolExtraction() throws {
        let source = """
        protocol Drawable {
            func draw()
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.types.first?.name == "Drawable")
        #expect(collector.types.first?.kind == .protocol)
    }

    @Test("TypeCollector extracts actor declarations")
    func testActorExtraction() throws {
        let source = """
        actor DataStore {
            var items: [String] = []
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.types.first?.name == "DataStore")
        #expect(collector.types.first?.kind == .actor)
    }

    @Test("TypeCollector extracts inheritance relationships")
    func testInheritanceExtraction() throws {
        let source = """
        class Animal {}
        class Dog: Animal {}
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 2)
        let dog = collector.types.first { $0.name == "Dog" }
        #expect(dog?.inheritedTypes.contains("Animal") == true)
    }

    @Test("TypeCollector extracts generic parameters")
    func testGenericExtraction() throws {
        let source = """
        struct Container<T, U> {
            var value: T
            var other: U
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.types.first?.genericParameters == ["T", "U"])
    }

    @Test("TypeCollector extracts extensions")
    func testExtensionExtraction() throws {
        let source = """
        struct MyType {}
        extension MyType: Equatable {}
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        #expect(collector.types.count == 1)
        #expect(collector.extensions.count == 1)
        #expect(collector.extensions.first?.extendedType == "MyType")
        #expect(collector.extensions.first?.inheritedTypes.contains("Equatable") == true)
    }

    @Test("buildDiagram generates valid Mermaid syntax")
    func testDiagramGeneration() throws {
        let source = """
        class Parent {}
        class Child: Parent {
            var name: String
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        let diagram = collector.buildDiagram(title: "Test Diagram")

        #expect(diagram.contains("title: Test Diagram"))
        #expect(diagram.contains("classDiagram"))
        #expect(diagram.contains("class Parent"))
        #expect(diagram.contains("class Child"))
        #expect(diagram.contains("Child --|> Parent"))
    }

    @Test("Access levels are correctly mapped")
    func testAccessLevels() throws {
        let source = """
        class Example {
            public var publicVar: Int
            private var privateVar: Int
            internal var internalVar: Int
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        let members = collector.types.first?.members ?? []
        let publicMember = members.first { $0.name == "publicVar" }
        let privateMember = members.first { $0.name == "privateVar" }
        let internalMember = members.first { $0.name == "internalVar" }

        #expect(publicMember?.accessLevel == .public)
        #expect(privateMember?.accessLevel == .private)
        #expect(internalMember?.accessLevel == .internal)
    }

    @Test("Static members are detected")
    func testStaticMembers() throws {
        let source = """
        class Example {
            static var count: Int = 0
            var instance: String
        }
        """

        let collector = TypeCollector()
        let syntax = parseSource(source)
        collector.walk(syntax)

        let members = collector.types.first?.members ?? []
        let staticMember = members.first { $0.name == "count" }
        let instanceMember = members.first { $0.name == "instance" }

        #expect(staticMember?.isStatic == true)
        #expect(instanceMember?.isStatic == false)
    }
}

// MARK: - Helper

import SwiftSyntax
import SwiftParser

private func parseSource(_ source: String) -> SourceFileSyntax {
    Parser.parse(source: source)
}

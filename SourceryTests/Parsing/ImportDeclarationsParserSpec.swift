//
//  Created by Alexander Balaban on 16/12/2019.
//  Copyright © 2019 Pixle. All rights reserved.
//

import Quick
import Nimble
import PathKit
import SourceKittenFramework
@testable import Sourcery
@testable import SourceryFramework
@testable import SourceryRuntime

class ImportDeclarationsParserSpec: QuickSpec {
    override func spec() {
        describe("ImportDeclarationsParser") {
            describe("parse(contents:tokens:)") {
                func makeTokens(from components: [String], kinds: [SyntaxKind]) -> [SyntaxToken] {
                    precondition(components.count == kinds.count)
                    var accum = 0
                    return zip(components, kinds).map { (args) -> SyntaxToken in
                        let (component, kind) = args
                        let token = SyntaxToken(type: kind.rawValue, offset: accum, length: component.utf8.count)
                        accum += component.utf8.count + 1
                        return token
                    }
                }
                func parse(_ contents: String, tokens: [SyntaxToken]) -> [ImportDeclaration] {
                    return ImportDeclarationsParser.parse(from: contents, with: tokens)
                }

                it("extracts simple import") {
                    let components = ["import", "Foundation"]
                    let kinds: [SyntaxKind] = [.keyword, .identifier]
                    let tokens = makeTokens(from: components, kinds: kinds)

                    let expectedDeclaration = ImportDeclaration(attribute: .none, kind: nil, path: [components[1]])
                    let declaration = parse(components.joined(separator: " "), tokens: tokens).first

                    expect(declaration).to(equal(expectedDeclaration))
                }

                it("extracts multiple imports") {
                    let path = ["CoreData", "version"]
                    let components = ["import", "Foundation", "\n", "@testable", "import", "let"]
                    let kinds: [SyntaxKind] = [.keyword, .identifier, .string, .keyword, .keyword, .keyword, .identifier, .identifier]
                    let tokens = makeTokens(from: components + path, kinds: kinds)

                    let expectedFirstDeclaration = ImportDeclaration(attribute: .none, kind: nil, path: [components[1]])
                    let expectedSecondDeclaration = ImportDeclaration(attribute: .testable, kind: .let, path: path)

                    let contents = components + [path.joined(separator: ".")]
                    let declarations = parse(contents.joined(separator: " "), tokens: tokens)

                    expect(declarations.count).to(equal(2))
                    expect(declarations.first).to(equal(expectedFirstDeclaration))
                    expect(declarations.last).to(equal(expectedSecondDeclaration))
                }

                it("extracts import with attribute") {
                    let components = ["@testable", "import", "Foundation"]
                    let kinds: [SyntaxKind] = [.keyword, .keyword, .identifier]
                    let tokens = makeTokens(from: components, kinds: kinds)

                    let expectedDeclaration = ImportDeclaration(attribute: .testable, kind: nil, path: [components[2]])
                    let declaration = parse(components.joined(separator: " "), tokens: tokens).first

                    expect(declaration).to(equal(expectedDeclaration))
                }

                it("extracts import with kind") {
                    let components = ["import", "func", "Foundation"]
                    let kinds: [SyntaxKind] = [.keyword, .keyword, .identifier]
                    let tokens = makeTokens(from: components, kinds: kinds)

                    let expectedDeclaration = ImportDeclaration(attribute: .none, kind: .func, path: [components[2]])
                    let declaration = parse(components.joined(separator: " "), tokens: tokens).first

                    expect(declaration).to(equal(expectedDeclaration))
                }

                it("extracts module import") {
                    let path = ["Foundation", "Module"]
                    let components = ["import"]
                    let kinds: [SyntaxKind] = [.keyword, .identifier, .identifier]
                    let tokens = makeTokens(from: components + path, kinds: kinds)

                    let expectedDeclaration = ImportDeclaration(attribute: .none, kind: nil, path: path)
                    let contents = components + [path.joined(separator: ".")]
                    let declaration = parse(contents.joined(separator: " "), tokens: tokens).first

                    expect(declaration).to(equal(expectedDeclaration))
                }

                it("extracts nothing when there is no import") {
                    let path = ["Foundation", "Module"]
                    let components = ["struct"]
                    let kinds: [SyntaxKind] = [.keyword, .identifier, .identifier]
                    let tokens = makeTokens(from: components + path, kinds: kinds)

                    let contents = components + [path.joined(separator: ".")]
                    let declaration = parse(contents.joined(separator: " "), tokens: tokens).first

                    expect(declaration).to(beNil())
                }

                it("extracts import with attribute, kind, and complex path") {
                    let path = ["Foundation", "Func", "Sort"]
                    let components = ["@testable", "import", "func"]
                    let kinds: [SyntaxKind] = [.keyword, .keyword, .keyword, .identifier, .identifier, .identifier]
                    let tokens = makeTokens(from: components + path, kinds: kinds)

                    let expectedDeclaration = ImportDeclaration(attribute: .testable, kind: .func, path: path)
                    let contents = components + [path.joined(separator: ".")]
                    let declaration = parse(contents.joined(separator: " "), tokens: tokens).first

                    expect(declaration).to(equal(expectedDeclaration))
                }
            }
        }
    }
}

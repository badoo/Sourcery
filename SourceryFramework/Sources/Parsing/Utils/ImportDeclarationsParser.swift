//
//  Created by Alexander Balaban on 16/12/2019.
//  Copyright © 2019 Pixle. All rights reserved.
//

import SourceryRuntime
import SourceKittenFramework

///
/// Parser for Import declarations
/// Details about the definition of the import declaration can be found here:
///    https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_import-declaration
///
public struct ImportDeclarationsParser {
    public var declarationsDescriptions: [String] {
        return self.declarations.map { $0.description }
    }

    private let declarations: [ImportDeclaration]
    private let contents: String

    /// Initializes parser
    ///
    /// - Parameter contents: Contents to parse
    /// - Parameter tokens: Tokens from SourceKit syntax response
    init(contents: String, tokens: [SyntaxToken]) {
        self.declarations = ImportDeclarationsParser.parse(from: contents, with: tokens)
        self.contents = contents
    }

    static func parse(from contents: String, with tokens: [SyntaxToken]) -> [ImportDeclaration] {
        let tokens = tokens.sorted { $0.offset < $1.offset }
        let tokensWithContent = tokens.map { (token) -> (SyntaxToken, String.SubSequence) in
            let startIndex = contents.utf8.index(contents.startIndex, offsetBy: token.offset)
            let endIndex = contents.utf8.index(startIndex, offsetBy: token.length)
            return (token, contents[startIndex..<endIndex])
        }

        var declarations = [ImportDeclaration]()
        for var idx in (0..<tokensWithContent.count) {
            let (token, value) = tokensWithContent[idx]

            // Proceed only if `import` keyword exists
            guard let tokenKind = SyntaxKind(rawValue: token.type), tokenKind == .keyword, value == "import" else { continue }

            // Parse attributes of the import
            let attribute: ImportDeclaration.Attribute
            if idx - 1 >= 0 {
                let (_, prevContent) = tokensWithContent[idx - 1]
                attribute = ImportDeclaration.Attribute(rawValue: String(prevContent)) ?? .none
            } else {
                attribute = .none
            }
            idx += 1

            // Parse kind of the import
            let kind: ImportDeclaration.Kind?
            let (_, nextContent) = tokensWithContent[idx]
            if let declarationKind = ImportDeclaration.Kind(rawValue: String(nextContent)) {
                kind = declarationKind
                idx += 1
            } else {
                kind = nil
            }

            // Parse path of the import
            var path = ImportDeclaration.Path()
            while idx < tokensWithContent.count {
                let (token, content) = tokensWithContent[idx]
                guard let tokenKind = SyntaxKind(rawValue: token.type), tokenKind == .identifier else { break }
                path.append(String(content))
                if idx + 1 < tokensWithContent.count {
                    let (nextToken, _) = tokensWithContent[idx + 1]
                    guard nextToken.offset - 1 == (token.offset + token.length) else { break }
                    guard contents[contents.index(contents.startIndex, offsetBy: nextToken.offset - 1)] == "." else { break }
                }
                idx += 1
            }

            let declaration = ImportDeclaration(attribute: attribute,
                                                kind: kind,
                                                path: path)
            declarations.append(declaration)
        }

        return declarations
    }
}

internal struct ImportDeclaration: Equatable, CustomStringConvertible {
    internal enum Attribute: String {
        case none
        case testable = "@testable"
    }
    internal enum Kind: String {
        case `typealias`
        case `struct`
        case `class`
        case `enum`
        case `protocol`
        case `let`
        case `var`
        case `func`
    }
    typealias Path = [String]

    internal let attribute: Attribute
    internal let kind: Kind?
    internal let path: Path

    var description: String {
        var components = [String]()
        if self.attribute == .testable {
            components.append(attribute.rawValue)
        }
        components.append("import")
        if let kind = self.kind {
            components.append(kind.rawValue)
        }
        components.append(self.path.joined(separator: "."))
        return components.joined(separator: " ")
    }
}

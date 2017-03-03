//
//  InternetMessageLineCategory.swift
//  XNW
//
//  Created by Daryle Walker on 2/26/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


/// The kinds of lines found while reading and building Internet message headers.
public enum InternetMessageLineCategory {

    // MARK: Cases

    case empty  // Empty line, ends the header section
    case headerStart(name: [UInt8], body: [UInt8])  // First line of a header field
    case headerContinuation  // Subsequent wrapped lines of a header field
    case allBlanks  // All standard-spaces and/or horizontal-tabs; legal under obsolete header field syntax
    case other  // Any (non-)matching line

    // MARK: Properties

    // Standard space
    private static let sp: UInt8 = 0x20
    // Horizontal tab
    private static let ht: UInt8 = 0x09
    // Colon
    private static let colon: UInt8 = 0x3A

    // MARK: Parsing

    /**
        Analyze the given line as text to check which part of a header field it is.

        - Parameter line: The line to check.  It must be octet-oriented with values in a ASCII character superset.  (All post-ASCII values are no-matches, so UTF-8 vs. ISO Latin-1 vs. etc. doesn't matter.)  It must *not* have any line-breaking characters (CR or LF).

        - Returns: Which type of header field line segment `line` is.

        - ToDo: Make this method work with any `Collection` with `UInt8` elements, not just `Data`.
    */
    public static func categorize(line: Data) -> InternetMessageLineCategory {
        // Trivial
        if line.isEmpty {
            return .empty
        }
        // Two choices with a common prefix
        if [ht, sp].contains(line.first!) {
            // All-blank line in the header section is obsolete syntax
            return line.contains(where: { ![ht, sp].contains($0) }) ? .headerContinuation : .allBlanks
        }
        // Check for a header field first line, which must have a colon separating name from body
        let colonSections = line.split(separator: colon, maxSplits: 1, omittingEmptySubsequences: false)
        if let potentialHeaderFieldName = colonSections.first, colonSections.count == 2 {
            // Obsolete syntax allows blanks between the name proper and the colon
            let blankSections = potentialHeaderFieldName.split(maxSplits: .max, omittingEmptySubsequences: false, whereSeparator: { [ht, sp].contains($0) })
            if let headerFieldName = blankSections.first, !headerFieldName.isEmpty {
                // Any blanks preceding the name proper is illegal
                if blankSections.map({ $0.count }).filter({ $0 > 0 }).count == 1 {
                    // All the non-blanks are together, and at the start of the pre-colon line segment
                    return .headerStart(name: Array(headerFieldName), body: Array(colonSections.last!))
                }
            }
        }
        // Anything else cannot be in a line designating (part of) a header field
        return .other
    }

}

// MARK: - Operations

extension InternetMessageLineCategory: Equatable {

    public static func ==(lhs: InternetMessageLineCategory, rhs: InternetMessageLineCategory) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty), (.headerContinuation, .headerContinuation), (.allBlanks, .allBlanks), (.other, .other):
            return true
        case let (.headerStart(n0, b0), .headerStart(n1, b1)):
            return n0 == n1 && b0 == b1
        case (.empty, _), (.headerStart, _), (.headerContinuation, _), (.allBlanks, _), (.other, _):
            return false
        }
    }

}

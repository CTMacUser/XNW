//
//  InternetMessage.swift
//  XNW
//
//  Created by Daryle Walker on 2/19/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


/// Represents an object defined in the Internet Message Format, as described in RFC 5322.  The internationalized extensions are described in RFC 6532.
public protocol InternetMessage {

    /**
        The type of the ordered collection of header fields.

        Conforms to `Sequence`, instead of `Collection`, here because of the limitations of `NSOrderedSet`.  The elements need to conform to `InternetMessageHeaderField`.
     */
    associatedtype HeaderBlock: Sequence

    /// The headers of the message.
    var header: HeaderBlock { get }
    /**
        The (optional) body of the message.
     
        Line-breaks within should be stored in the Unix/X-era-macOS standard of LF-only ("\n").  Use of the Internet-standard CRLF sequence happens at externalization time.  Line lengths *should* be at most 78 characters, but **must** have a UTF-8 expansion of normalization form NFC that is at most 998 octets.
        Besides LF, other ASCII control characters should not appear.  The exceptions are horizontal-tab and form-feed (the later for archaic page breaks).  Raw CR characters definitely *should not* appear.
     */
    var body: String? { get }

    /**
        Check the potential header section for problems.  Besides checking each header field for problems, using `InternetMesageHeaderField.invalidations`, you may have collective invariants to check.

        The default implementation (given in a later extension) returns the problems for each field, removing repeated errors.

        - Parameter header: The header section, i.e. the list of header fields to analyze.
        - Parameter flagTooLongForTransmission: Check if any field, after sectioning into segments for line wrapping, has any segments too long to be safely transmitted over SMTP/NNTP/etc. and add that error flag if the check fails.
        - Parameter flagHasInternationalCharacters: Check if any field directly contains Unicode characters outside the ASCII range in its body (Post-ASCII characters encoded in the ASCII range are OK.) and add that error flag if the check fails.

        - Returns: All the errors found.  Empty if the header section passes all tests.
     */
    static func invalidationsOn(header: HeaderBlock, flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> [Error]
    /**
        Check the potential body string for problems.  The given string is always checked for embedded NUL and CR, the latter because the string is intended for internal use.  (The CR part of the CRLF sequence is treated as external and so is added at save and stripped at load.)  You may have your own invariants to check.

        The default implementation (given in a later extension) checks for NUL and CR and the possibly the other errors listed below, removing repeated errors.

        - Parameter body: The body string to analyze.
        - Parameter flagTooLongForTransmission: Check if `body` doesn't have any lines too long to be safely transmitted over SMTP/NNTP/etc. and add that error flag if the check fails.
        - Parameter flagHasInternationalCharacters: Check if `body` doesn't directly have Unicode characters outside the ASCII range (Post-ASCII characters encoded in the ASCII range are OK.) and add that error flag if the check fails.
     
        - Returns: All the errors found.  Empty if the body string passes all tests.
     */
    static func invalidationsOn(body: String, flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> [Error]
    /**
        Report on all the problems with this message, both property-specific and collective problems.

        The default implementation (given in a later extension) checks the header section and body string individually and returns the combined error lists.

        - Parameter flagTooLongForTransmission: Check if any line in the body or any (wrapped) header field isn't too long to be safely transmitted over SMTP/NNTP/etc. and add that error flag if the check fails.
        - Parameter flagHasInternationalCharacters: Check if the body or any header field doesn't directly have Unicode characters outside the ASCII range (Post-ASCII characters encoded in the ASCII range are OK.) and add that error flag if the check fails.

        - Returns: All the errors found.  Empty if the message passes all tests.
    */
    func invalidations(flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> [Error]

}

/// Represents a message that can be mutated.
public protocol MutableInternetMessage: InternetMessage {

    /// The headers of a message.  Shouldn't be set to a value (including mutations of elements) that would violate the get-mode invariants.
    var header: Self.HeaderBlock { get set }
    /// The (optional) body of a message.  Shouldn't be set to a value that would violate the get-mode invariants.
    var body: String? { get set }

}

// MARK: - Validation

extension InternetMessage {

    // Default implementation
    public static func invalidationsOn(header: HeaderBlock, flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> [Error] {
        var errors = Set<InternetMessageError>()
        for field in header {
            if let headerField = field as? InternetMessageHeaderField {
                errors.formUnion(headerField.invalidations(flagTooLongForTransmission: flagTooLongForTransmission, flagHasInternationalCharacters: flagHasInternationalCharacters))
            } else {
                errors.insert(.unknown)  // Not supposed to happen
            }
        }

        var result = Array<Error>()
        for error in errors {
            result.append(error)
        }
        return result
    }

    // Default implementation
    public static func invalidationsOn(body: String, flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> [Error] {
        var errors = Set<InternetMessageError>()
        let lines = body.components(separatedBy: "\n").map { $0.precomposedStringWithCanonicalMapping.utf8 }
        for line in lines {
            if flagTooLongForTransmission && line.count > InternetMessageConstants.maximumAllowedOctetsPerLine {
                errors.insert(.bodyHasLineTooLongForTransmission)
            }
            if flagHasInternationalCharacters && line.contains { $0 > 0x7F } {
                errors.insert(.bodyHasInvalidUnicodeCharacters)
            }
            if line.contains(0) {
                errors.insert(.bodyHasEmbeddedNul)
            }
            if line.contains(0x0D) {
                errors.insert(.bodyHasRawCarriageReturn)
            }
        }

        var result = Array<Error>()
        for error in errors {
            result.append(error)
        }
        return result
    }

    // Default implementation
    public func invalidations(flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> [Error] {
        var errors = Self.invalidationsOn(header: self.header, flagTooLongForTransmission: flagTooLongForTransmission, flagHasInternationalCharacters: flagHasInternationalCharacters)
        if let body = self.body {
            errors.append(contentsOf: Self.invalidationsOn(body: body, flagTooLongForTransmission: flagTooLongForTransmission, flagHasInternationalCharacters: flagHasInternationalCharacters))
        }
        return errors
    }

}

// MARK: - Serialization

extension InternetMessage {

    /// The header section as a single string.  Each header field takes up at least one line; using multiple when the field is too long.  The string is empty if there are no fields.
    public var headerAsInternalString: String {
        var wrappedLines = [String]()
        for field in self.header {
            if let headerField = field as? InternetMessageHeaderField {
                wrappedLines.append(contentsOf: headerField.wrappedLineSegments)
            }
        }
        return wrappedLines.joined(separator: "\n") + (!wrappedLines.isEmpty ? "\n" : "")
    }

    /// The message as a single string.  It's the header section followed by the body with an empty line between them.  The empty line is skipped if the body doesn't exist.  The string is empty if there are no header fields and no body.  If the caller needs the message to always end with a line break, check the string and add the break if needed.
    public var messageAsInternalString: String {
        var message = self.headerAsInternalString
        if let body = self.body {
            message.append("\n")
            message.append(body)
        }
        return message
    }

    /// The message as a data block.  The line endings are externalized to CRLF (instead of the only-LF for internal use).
    public var messageAsExternalData: Data {
        return self.messageAsInternalString.replacingOccurrences(of: "\n", with: "\r\n").precomposedStringWithCanonicalMapping.data(using: .utf8)!
    }

}

//
//  InternetMessage.swift
//  XNW
//
//  Created by Daryle Walker on 5/1/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation


/// Represents a record of the parts of a message in the Internet Message Format, described by RFC 822 and its updates.
public protocol InternetMessage {

    /// Further data needed to initialize a message in case the internal properties cannot be default-initialized.
    associatedtype Configuration
    /// The type (or superclass or protocol) used for the fields in the header.
    associatedtype HeaderFieldType: HeaderField

    /// The header section of the message.
    var header: [HeaderFieldType] { get set }  // Generalizing the type to RangeReplaceableCollectionType was too hard.
    /// The body of the message.
    var body: String? { get set }

    /**
        Create an instance from the given configuration.

        - parameter configuration: Input data needed to initialize any internal properties.  If `transformField` is overriden, then the data should include anything needed to create the new `HeaderField`-conforming objects.

        - postcondition: `self.header.isEmpty && self.body == nil`.
     */
    init(configuration: Configuration)

    /**
        Converts a sample header field created during parsing to an object more appropriate for this instance.  For example, if this conforming type uses Core Data, and needs its header fields to do the same, then it could copy the field data from `sample` into a `HeaderField` instance that derives from `NSManagedObject`.
        - parameter sample: The header field instance to convert.  Its initializer has already validated a name and body for use.
        - returns: A more suitable copy of `sample` to store in `header`.
     */
    func transformField(sample: ValidatingInitializerHeaderField) -> HeaderFieldType

}

// MARK: Message writing

extension InternetMessage {

    /// The body, as needed for a description: with a blank line separating it from the header.
    var bodyDescription: String {
        if let body = body {
            return LineBreaks.internalString + body
        }
        return ""
    }

}

public extension InternetMessage where HeaderFieldType: HeaderField {

    /// The message text, with each header field (in order) then the body (if any).  All the text for a header field is emitted as a single line.
    public var messageDescription: String {
        var headerDescription = ""
        for field in header {
            headerDescription += field.fieldDescription
            headerDescription += LineBreaks.internalString
        }
        return headerDescription + bodyDescription
    }

    /// Like `messageDescription`, but with as many header lines wrapped at 78 characters as possible.  You have to make sure any body text doesn't exceed that (or 998 octets at most) yourself.
    public var wrappedDescription: String {
        var headerDescription = ""
        for field in header {
            headerDescription += field.wrappedDescription
        }
        return headerDescription + bodyDescription
    }

    /// Like `wrappedDescription`, but as UTF-8 string data.  Suitable for file output.
    public var binaryDescription: NSData? {
        return wrappedDescription.componentsSeparatedByString(LineBreaks.internalString).joinWithSeparator(LineBreaks.internetMessageString).dataUsingEncoding(NSUTF8StringEncoding)
    }

}

// MARK: Integrity Checks

public extension InternetMessage {

    /// Whether or not any line in the body is wider than the 998 octet limit.
    public var bodyTooWide: Bool {
        return body?.componentsSeparatedByString(LineBreaks.internalString).map { $0.utf8.count }.maxElement() ?? 0 > InternetMessageConstants.maximumLineOctetLength
    }

    /// Whether or not the body has a forbidden character (NUL, loose CR, or loose LF; CRLF pairs are OK).
    public var bodyHasBannedCharacters: Bool {
        return !(body?.componentsSeparatedByString(LineBreaks.internalString).filter { $0.rangeOfCharacterFromSet(CharacterSets.messageBodyBannedStrict) != nil }.isEmpty ?? true)
    }

}

public extension InternetMessage where HeaderFieldType: HeaderField {

    /// Whether or not any header field can be printed without any of its segments violating the 998 octet limit.
    public var headerTooWide: Bool {
        return header.reduce(false) { $0 || $1.tooLong }
    }
    /// Whether or not either the header or body has a line longer than the 998 octet limit.
    public var tooWide: Bool {
        return headerTooWide || bodyTooWide
    }

}

// MARK: Message reading

public extension InternetMessage {

    /**
        Initialize from a message encoded as bulk data.

        - parameter configuration: Input data needed to initialize any internal properties.

        - parameter data: The serialized message.

        - parameter encodings: A prioritized (most important at index 0) list of encodings to use for conversion.  Defaults to: ASCII, UTF-8, Windows-1252 (i.e. Windows Latin-1), and Mac-Roman.

        - returns: `nil` if `data` could not be converted to a string before processing.

        - postcondition: `self` contains the deserialized message's data.
     */
    public init?(configuration: Configuration, data: NSData, encodings: [NSStringEncoding] = InternetMessageConstants.bestTextEncodings) {
        var convertedString: NSString?
        let encoding = NSString.stringEncodingForData(data, encodingOptions: [NSStringEncodingDetectionSuggestedEncodingsKey: encodings, NSStringEncodingDetectionUseOnlySuggestedEncodingsKey: !encodings.isEmpty], convertedString: &convertedString, usedLossyConversion: nil)
        guard let message = convertedString as? String where encoding != 0 else {
            return nil
        }

        self.init(configuration: configuration, string: message)
    }

    /**
        Initialize from a message encoded in a string.  If the string can't be parsed as a message, then all of its contents go into the message's body.

        - parameter configuration: Input data needed to initialize any internal properties.

        - parameter string: The serialized message.

        - postcondition: `self` contains the deserialized message's data.
    */
    public init(configuration: Configuration, string: String) {
        // Start with valid, but empty, sections so later code can append to them.
        self.init(configuration: configuration)

        // A header field can be spread over several lines, so store it until completion.
        var fieldNameAndBody: (name: String, body: String)?

        func flushHeaderField() {
            if let field = fieldNameAndBody {
                // Using "try!" since the name was already vetted in `processLine` and the body can take any text.
                header.append(transformField(try! UnstructuredHeaderField(name: field.name, body: field.body)))
                fieldNameAndBody = nil
            }
        }

        // The body gets one new line at a time.
        var haveBodyLines = false

        func processBodyLine(line: String) {
            if body != nil {
                if haveBodyLines {
                    body! += LineBreaks.internalString
                }
                body! += line
            } else {
                body = line
            }
            haveBodyLines = true
        }

        // Check how the line parses and append it to the body, header, or trial header field.
        var finishedHeader = false

        func processLine(line: String) {
            guard !finishedHeader else {
                processBodyLine(line)
                return
            }
            guard !line.isEmpty else {
                flushHeaderField()
                finishedHeader = true
                body = ""
                return
            }

            // Check for a header field initial or continuation (or all-whitespace) line.
            let colonSections = line.componentsSeparatedByString(":")
            if let firstUnichar = colonSections.first!.utf16.first {
                if CharacterSets.whitespace.characterIsMember(firstUnichar) {
                    if fieldNameAndBody != nil {
                        fieldNameAndBody!.body += line
                        return
                    }
                } else if colonSections.count > 1 {  // i.e. not a colon-less line.
                    let trimmedFieldName = colonSections.first!.stringByTrimmingCharactersInSet(CharacterSets.whitespace)
                    if let trialField = try? UnstructuredHeaderField(name: trimmedFieldName, body: colonSections.dropFirst().joinWithSeparator(":")) {
                        flushHeaderField()
                        fieldNameAndBody = (trialField.name, trialField.body)
                        return
                    }
                }
            }

            // Got something that can't be a header field line -> close the header and start the body.
            flushHeaderField()
            finishedHeader = true
            processBodyLine(line)
        }

        // Loop through each line, reconnecting lines that are terminated by Apple's standards but not by the IMF.
        var partialLine = ""
        var lastLineTerminated = false
        partialLine.reserveCapacity(string.characters.count)
        string.enumerateSubstringsInRange(string.characters.indices, options: .ByLines) {
            substring, substringRange, enclosingRange, stop in

            partialLine += substring!
            assert(substringRange.startIndex == enclosingRange.startIndex)
            let terminator = string[substringRange.endIndex..<enclosingRange.endIndex]
            switch terminator {
            case "\r", "\n", "\r\n", "":
                processLine(partialLine)
                partialLine = ""
                // Unlike the NSString version, this method does read in the last line if it was unterminated.
                lastLineTerminated = !terminator.isEmpty
            default:
                partialLine += terminator
                lastLineTerminated = false
            }
        }

        // Clean up after the last line read, including the copying the terminator if the last line was terminated.
        if fieldNameAndBody != nil {
            flushHeaderField()
        } else if lastLineTerminated && haveBodyLines {
            processBodyLine("")
        }
    }

}

// MARK: Convenience Initializers

public extension InternetMessage where Configuration == Void {

    /// Default-initialize without the redundant parameter.
    public init() {
        self.init(configuration: ())
    }

}

public extension InternetMessage where Configuration == Void {

    /// Initialize from parsing data (with possible encodings) wihout the redundant parameter.
    public init?(data: NSData, encodings: [NSStringEncoding] = InternetMessageConstants.bestTextEncodings) {
        self.init(configuration: (), data: data, encodings: encodings)
    }
    /// Initialize from parsing a string without the redundant parameter.
    public init(string: String) {
        self.init(configuration: (), string: string)
    }

}

// MARK: - Constants for Message Limits

public enum InternetMessageConstants {

    /// The preferred maximum line length, not counting the trailing CRLF, in characters.  (RFC 5322, section 2.1.1)
    public static let preferredMaximumLineCharacterLength = 78
    /// The hard maximum line length, not counting the trailing CRLF, in octets.  (RFC 5322, section 2.1.1; RFC 6532, section 3.4)  Due to the maximum ratio of characters to UTF-8 chains (6 in original spec, 4 when limited to 21-bit code points), the preferred line length translated to octets can't reach this.  Value based on SMTP's 1000 octet size per transmitted line.
    public static let maximumLineOctetLength = 1000 - "\r\n".utf8.count  // ".characters.count" reports 1 (instead of 2)!

    /// The best encodings to try out when converting raw data to text.
    private static let bestTextEncodings: [NSStringEncoding] = [
        NSASCIIStringEncoding, NSUTF8StringEncoding, NSWindowsCP1252StringEncoding, NSMacOSRomanStringEncoding
    ]

}

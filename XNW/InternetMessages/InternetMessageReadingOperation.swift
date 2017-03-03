//
//  InternetMessageReadingOperation.swift
//  XNW
//
//  Created by Daryle Walker on 3/1/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


/// Form a construct in the Internet Message Format from a block of (UTF-8) data.
public class InternetMessageReadingOperation: Operation, InternetMessage {

    // MARK: Types

    /// Simple storage of header field information.
    public struct HeaderField: InternetMessageHeaderField {
        public fileprivate(set) var name: String
        public fileprivate(set) var body: String
    }

    // MARK: Properties

    public private(set) var header: [HeaderField]
    public private(set) var body: String?

    /// Whether the input text really started a proper message.
    public private(set) var isProperMessage: Bool?

    // The extractor of lines from the data.
    private var reader: LineReader
    // Whether to strip the leading space from header field bodies.
    private let stripSpace: Bool

    // MARK: Initializers

    /**
        Create an operation to parse an e-mail message from the given data.

        The operation gets header-field lines read and put into the header section until no more qualifying lines are found, and then the remaining lines (if any) are dumped into the body.  If the first line is neither a header-field first line nor an empty line, the entirety of the lines are dumped into the body.

        Do *not* read the public properties (`header`, `body`, `isProperMessage`) until the operation is finished, to prevent multithreading consistency issues.

        - Parameter data: The data to parse.
        - Parameter stripFieldBodyLeadingSpace: If the body of a read header field begins with a space, remove that space before storage.  This is a counter to a leading space tending to be added to field bodies on write.  The space will *not* be removed if it's the only character.  Defaults to `true`.

        - Postcondition:
            - The message starts empty (`header.isEmpty && body == nil`).
            - `isProperMessage == nil`
     */
    public init(data: Data, stripFieldBodyLeadingSpace: Bool = true) {
        header = []
        stripSpace = stripFieldBodyLeadingSpace
        reader = LineReader(data: data)
    }

    // MARK: Overrides

    override public func main() {
        // Read the header.
        isProperMessage = true
        readHeader: while let headerLine = reader.next() {
            guard !isCancelled else { return }

            switch InternetMessageLineCategory.categorize(line: headerLine.data(using: .utf8)!) {
            case .headerStart(let fieldName, var fieldBody):
                if stripSpace && fieldBody.count > 1 && fieldBody.first! == 0x20 {
                    fieldBody.removeFirst()
                }
                header.append(HeaderField(name: LineReader.stringConverted(from: Data(bytes: fieldName)), body: LineReader.stringConverted(from: Data(bytes: fieldBody))))
            case .headerContinuation, .allBlanks:
                if header.isEmpty {
                    fallthrough
                } else {
                    header[header.endIndex - 1].body.append(headerLine)
                }
            case .empty, .other:
                isProperMessage = headerLine.isEmpty
                body = headerLine
                if !isProperMessage! && reader.previousHadTerminator! {
                    body!.append("\n")
                }
                break readHeader
            }
        }

        // Read the body.
        while let bodyLine = reader.next() {
            guard !isCancelled else { return }

            body!.append(bodyLine + (reader.previousHadTerminator! ? "\n" : ""))
        }
    }

}

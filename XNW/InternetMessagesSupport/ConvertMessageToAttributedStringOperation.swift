//
//  ConvertMessageToAttributedStringOperation.swift
//  XNW
//
//  Created by Daryle Walker on 3/4/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation
import AppKit
import InternetMessages


/// Render data in the Internet Message Format as a attributed-string.
public class ConvertMessageToAttributedStringOperation: Operation {

    // MARK: Types

    // For each header field, store the line text and how long the name is.
    typealias HeaderInfo = (line: String, nameLength: Int)

    // MARK: Properties

    /// The converted message.
    public private(set) var messageString = NSAttributedString()

    /// The font for the header section.
    public var headerBaseFont = NSFont.userFont(ofSize: 0)!
    /// The font for the body.
    public var bodyFont = NSFont.userFixedPitchFont(ofSize: 0)!

    // The header
    var headerLines: [HeaderInfo] = []
    // The body
    var body: String?

    // MARK: Initializers

    /**
        Create an operation to serialize an e-mail message as an attributed string.

        Do *not* read `messageString` until the operation is finished, to prevent multithreading consistency issues.

        Similarly, do not write to `headerBaseFont` or `bodyFont` after the operation has started.

        - Parameter message: The message to convert.
     */
    public init<M: InternetMessage>(message: M) {
        for field in message.header {
            if let headerField = field as? InternetMessageHeaderField {
                headerLines.append((line: headerField.line, nameLength: headerField.name.characters.count))
            }
        }
        body = message.body
    }

    // MARK: Overrides

    public override func main() {
        // Set the paragraph formatting for each header line
        let headerAdvancement = headerBaseFont.maximumAdvancement
        let headerIndent = max(headerAdvancement.width, headerAdvancement.height) / 2.0
        let headerParagraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        headerParagraphStyle.headIndent = headerIndent
        headerParagraphStyle.lineBreakMode = .byWordWrapping

        // Write out each header line
        let result = NSMutableAttributedString()
        for headerLine in headerLines {
            guard !isCancelled else { return }

            // Set each header line
            let richHeaderLine = NSMutableAttributedString(string: headerLine.line + "\n", attributes: [NSFontAttributeName: headerBaseFont, NSParagraphStyleAttributeName: headerParagraphStyle])
            let leaderMark = headerLine.nameLength + 1
            richHeaderLine.applyFontTraits(.boldFontMask, range: NSMakeRange(0, leaderMark))
            richHeaderLine.applyFontTraits(.unboldFontMask, range: NSMakeRange(leaderMark, richHeaderLine.length - leaderMark))
            result.append(richHeaderLine)
        }

        // Write out the body (and its preceding separator line)
        if let body = body {
            guard !isCancelled else { return }

            // Set the paragraph formatting for the body...
            let bodyAdvancement = bodyFont.maximumAdvancement
            let bodyIndent = max(bodyAdvancement.width, bodyAdvancement.height) / 2.0
            let bodyParagraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
            bodyParagraphStyle.headIndent = bodyIndent
            bodyParagraphStyle.lineBreakMode = .byWordWrapping

            // ...and separator
            let separatorTable = NSTextTable()
            separatorTable.numberOfColumns = 1

            let separatorBlock = NSTextTableBlock(table: separatorTable, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)
            separatorBlock.setWidth(2.0, type: .percentageValueType, for: .padding, edge: .minX)
            separatorBlock.setWidth(2.0, type: .percentageValueType, for: .padding, edge: .maxX)

            let separatorStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
            separatorStyle.textBlocks = [separatorBlock]
            separatorStyle.paragraphSpacing = bodyFont.ascender - bodyFont.descender + bodyFont.leading
            separatorStyle.paragraphSpacingBefore = separatorStyle.paragraphSpacing

            // Set the body, but add a line for the initial separator
            // (Separator creation inspired by <http://stackoverflow.com/a/26844989/1010226>.)
            let richSeparator = NSAttributedString(string: "\u{A0}\t\u{A0}\n", attributes: [NSParagraphStyleAttributeName: separatorStyle, NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue])
            let richBody = NSAttributedString(string: body, attributes: [NSFontAttributeName: bodyFont, NSParagraphStyleAttributeName: bodyParagraphStyle])
            result.append(richSeparator)
            result.append(richBody)
        }

        // Finish up
        result.fixAttributes(in: NSMakeRange(0, result.length))
        messageString = result.copy() as! NSAttributedString
    }

}

//
//  InternetMessageReadingOperationTests.swift
//  XNW
//
//  Created by Daryle Walker on 3/1/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import XCTest
@testable import InternetMessages


class InternetMessageReadingOperationTests: XCTestCase {

    // "Mary had a little lamb", first verse, from "Denslow's Mother Goose" by W. W. Denslow
    static let mary = [
        "Mary had a little lamb,",
        "Its fleece was white as snow;",
        "And everywhere that Mary went,",
        "The lamb was sure to go."
    ]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Check reading empty data
    func testReadingEmptyData() {
        let operation = InternetMessageReadingOperation(data: Data())
        operation.start()
        XCTAssert(operation.isFinished)
        XCTAssert(operation.header.isEmpty)
        XCTAssertNil(operation.body)
        XCTAssertEqual(operation.isProperMessage, true)
    }

    // Check a single unterminated line, for each type
    // (Unterminated empty line not provided since it'd be the same as empty data.)
    func testSingleLines() {
        let headerStartLine = "Hello: World"
        let headerContinueLine = "\tGoodbye"
        let allBlankLine = " "
        let otherLine = "other"
        var operation = InternetMessageReadingOperation(data: headerStartLine.data(using: .utf8)!)
        operation.start()
        XCTAssertEqual(operation.header.count, 1)
        XCTAssertEqual(operation.header.first?.name, "Hello")
        XCTAssertEqual(operation.header.first?.body, "World")
        XCTAssertNil(operation.body)
        XCTAssertEqual(operation.isProperMessage, true)

        operation = InternetMessageReadingOperation(data: headerContinueLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, headerContinueLine)
        XCTAssertEqual(operation.isProperMessage, false)

        operation = InternetMessageReadingOperation(data: allBlankLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, allBlankLine)
        XCTAssertEqual(operation.isProperMessage, false)

        operation = InternetMessageReadingOperation(data: otherLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, otherLine)
        XCTAssertEqual(operation.isProperMessage, false)
    }

    // Check a single terminated line, for each type
    func testSingleTerminatedLines() {
        let emptyLine = "\n"
        let headerStartLine = "Hello: World\n"
        let headerContinueLine = "\tGoodbye\n"
        let allBlankLine = " \n"
        let otherLine = "other\n"
        var operation = InternetMessageReadingOperation(data: emptyLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, "")
        XCTAssertEqual(operation.isProperMessage, true)

        operation = InternetMessageReadingOperation(data: headerStartLine.data(using: .utf8)!)
        operation.start()
        XCTAssertEqual(operation.header.count, 1)
        XCTAssertEqual(operation.header.first?.name, "Hello")
        XCTAssertEqual(operation.header.first?.body, "World")
        XCTAssertNil(operation.body)
        XCTAssertEqual(operation.isProperMessage, true)

        operation = InternetMessageReadingOperation(data: headerContinueLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, headerContinueLine)
        XCTAssertEqual(operation.isProperMessage, false)

        operation = InternetMessageReadingOperation(data: allBlankLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, allBlankLine)
        XCTAssertEqual(operation.isProperMessage, false)

        operation = InternetMessageReadingOperation(data: otherLine.data(using: .utf8)!)
        operation.start()
        XCTAssert(operation.header.isEmpty)
        XCTAssertEqual(operation.body, otherLine)
        XCTAssertEqual(operation.isProperMessage, false)
    }

    // Check multi-line header fields
    func testMultipleLineHeader() {
        let mary = InternetMessageReadingOperationTests.mary
        let headerString = "Line1:\(mary[0])\nLine2:\(mary[1])\r\t\(mary[2])\n \(mary[3])"
        var operation = InternetMessageReadingOperation(data: headerString.data(using: .utf8)!)
        operation.start()
        XCTAssertEqual(operation.header.count, 2)
        XCTAssertEqual(operation.header.first?.name, "Line1")
        XCTAssertEqual(operation.header.first?.body, mary[0])
        XCTAssertEqual(operation.header.last?.name, "Line2")
        XCTAssertEqual(operation.header.last?.body, "\(mary[1])" + "\t\(mary[2])" + " \(mary[3])")
        XCTAssertNil(operation.body)
        XCTAssertEqual(operation.isProperMessage, true)

        // Recheck with a line terminator at the end
        operation = InternetMessageReadingOperation(data: (headerString + "\r\r\n").data(using: .utf8)!)
        operation.start()
        XCTAssertEqual(operation.header.count, 2)
        XCTAssertEqual(operation.header.first?.name, "Line1")
        XCTAssertEqual(operation.header.first?.body, mary[0])
        XCTAssertEqual(operation.header.last?.name, "Line2")
        XCTAssertEqual(operation.header.last?.body, "\(mary[1])" + "\t\(mary[2])" + " \(mary[3])")  // No change
        XCTAssertNil(operation.body)
        XCTAssertEqual(operation.isProperMessage, true)
    }

    // Check header-less message
    func testHeaderlessMessage() {
        let mary = InternetMessageReadingOperationTests.mary
        let bodyString = "\n\(mary[1])\r\(mary[3])"
        var operation = InternetMessageReadingOperation(data: bodyString.data(using: .utf8)!)
        operation.start()
        XCTAssertTrue(operation.header.isEmpty)
        XCTAssertEqual(operation.body, "\(mary[1])\n\(mary[3])")  // Changed CR to LF
        XCTAssertEqual(operation.isProperMessage, true)

        // Recheck with a line terminator at the end
        operation = InternetMessageReadingOperation(data: (bodyString + "\r\n").data(using: .utf8)!)
        operation.start()
        XCTAssertTrue(operation.header.isEmpty)
        XCTAssertEqual(operation.body, "\(mary[1])\n\(mary[3])\n")  // Also changed new CRLF to LF
        XCTAssertEqual(operation.isProperMessage, true)
    }

    // Check message with proper separator between header and body
    func testProperlySeparatedMessage() {
        let mary = InternetMessageReadingOperationTests.mary
        let headerString = "Line1  :\r\n" + "Line2:\(mary[0])\n" + " \(mary[2])\r"
        let bodyString = mary[3] + "\r" + mary[1] + "\r\r\n"
        let messageString = "\(headerString)\r\(bodyString)"
        let operation = InternetMessageReadingOperation(data: messageString.data(using: .utf8)!)
        operation.start()
        XCTAssertEqual(operation.header.count, 2)
        XCTAssertEqual(operation.header.first?.name, "Line1")  // Spaces before separating colon not included
        XCTAssertEqual(operation.header.first?.body, "")  // OK to have nothing after separating colon
        XCTAssertEqual(operation.header.last?.name, "Line2")
        XCTAssertEqual(operation.header.last?.body, "\(mary[0]) \(mary[2])")
        XCTAssertEqual(operation.body, "\(mary[3])\n\(mary[1])\n")
        XCTAssertEqual(operation.isProperMessage, true)
    }

    // Check message with improper separator between header and body
    func testImproperlySeparatedMessage() {
        let mary = InternetMessageReadingOperationTests.mary
        let headerString = "Line1  :\r\n" + "Line2:\(mary[0])\n" + " \(mary[2])\r"
        let bodyString = mary[3] + "\r" + mary[1] + "\r\r\n"
        let messageString = "\(headerString)\(bodyString)"  // No blank-line separator
        let operation = InternetMessageReadingOperation(data: messageString.data(using: .utf8)!)
        operation.start()
        XCTAssertEqual(operation.header.count, 2)
        XCTAssertEqual(operation.header.first?.name, "Line1")
        XCTAssertEqual(operation.header.first?.body, "")
        XCTAssertEqual(operation.header.last?.name, "Line2")
        XCTAssertEqual(operation.header.last?.body, "\(mary[0]) \(mary[2])")
        XCTAssertEqual(operation.body, "\(mary[3])\n\(mary[1])\n")
        XCTAssertEqual(operation.isProperMessage, false)
    }

    // Check space-stripping after the colon in a header field
    func testSpaceStripping() {
        let none = "Hello:"
        let justASpace = "Hello: "
        let noSpace = "Hello:World"
        let oneSpace = "Hello: World"
        let twoSpaces = "Hello:  World"
        var operation = InternetMessageReadingOperation(data: none.data(using: .utf8)!, stripFieldBodyLeadingSpace: true)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, "")
        operation = InternetMessageReadingOperation(data: none.data(using: .utf8)!, stripFieldBodyLeadingSpace: false)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, "")

        operation = InternetMessageReadingOperation(data: justASpace.data(using: .utf8)!, stripFieldBodyLeadingSpace: true)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, " ")
        operation = InternetMessageReadingOperation(data: justASpace.data(using: .utf8)!, stripFieldBodyLeadingSpace: false)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, " ")

        operation = InternetMessageReadingOperation(data: noSpace.data(using: .utf8)!, stripFieldBodyLeadingSpace: true)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, "World")
        operation = InternetMessageReadingOperation(data: noSpace.data(using: .utf8)!, stripFieldBodyLeadingSpace: false)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, "World")

        operation = InternetMessageReadingOperation(data: oneSpace.data(using: .utf8)!, stripFieldBodyLeadingSpace: true)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, "World")
        operation = InternetMessageReadingOperation(data: oneSpace.data(using: .utf8)!, stripFieldBodyLeadingSpace: false)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, " World")

        operation = InternetMessageReadingOperation(data: twoSpaces.data(using: .utf8)!, stripFieldBodyLeadingSpace: true)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, " World")
        operation = InternetMessageReadingOperation(data: twoSpaces.data(using: .utf8)!, stripFieldBodyLeadingSpace: false)
        operation.start()
        XCTAssertEqual(operation.header.first?.body, "  World")
    }

}

//
//  InternetMessageTests.swift
//  XNW
//
//  Created by Daryle Walker on 2/21/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import XCTest
@testable import InternetMessages


class InternetMessageTests: XCTestCase {

    // A simple implementation of a header field
    struct SimpleHeaderField: InternetMessageHeaderMutableField {

        var name = ""
        var body = ""

    }

    // A simple implementation of a message
    struct SimpleMessage: InternetMessage {

        var header: [SimpleHeaderField] = []
        var body: String?

    }

    // A malformed message type
    struct BadMessage: InternetMessage {
        var header: [Int] = []  // Doesn't conform to `InternetMessageHeaderField`, but Swift descriptions aren't refined enough to flag the problem.
        var body: String?
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    // Test what happens when the wrong type is used for the header fields.
    func testBadHeaderType() {
        // A flaw is that there needs to be at least one element to flag a type-mismatch error.
        XCTAssertTrue(BadMessage.invalidationsOn(header: [], flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(BadMessage.invalidationsOn(header: [], flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(BadMessage.invalidationsOn(header: [], flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(BadMessage.invalidationsOn(header: [], flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)

        // Now a type-mismatch will be found.
        XCTAssertEqual(BadMessage.invalidationsOn(header: [1], flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.unknown])
        XCTAssertEqual(BadMessage.invalidationsOn(header: [2, 3], flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [.unknown])
        XCTAssertEqual(BadMessage.invalidationsOn(header: [4, 5, 6], flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.unknown])
        XCTAssertEqual(BadMessage.invalidationsOn(header: [7, 8, 9, 10], flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.unknown])
    }

    // Test validation on header sections.
    func testHeaderValidation() {
        // Empty header
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [], flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [], flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [], flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [], flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // One good header field
        var field1 = SimpleHeaderField(name: "Hello", body: "World")
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)
        
        // Bad field name
        field1.name = "Héllo"
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.headerFieldNameHasInvalidCharacters])
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [.headerFieldNameHasInvalidCharacters])
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.headerFieldNameHasInvalidCharacters])
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.headerFieldNameHasInvalidCharacters])

        // Bad field body
        field1.name = "Hello"
        field1.body = String(repeating: "a", count: 1000)
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [])
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [])
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.headerFieldCouldNotBeWrappedForTransmission])
        XCTAssertEqual(SimpleMessage.invalidationsOn(header: [field1], flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.headerFieldCouldNotBeWrappedForTransmission])
    }

    // Test validation on bodies.
    func testBodyValidation() {
        // Empty body
        var body = ""
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // Normal, single uncapped line
        body = "Hello World"
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // Normal, with terminated lines
        body = "Hello World\nGoodbye, planet.\n"
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // Line too long
        body = String(repeating: "b", count: 1000)
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasLineTooLongForTransmission])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.bodyHasLineTooLongForTransmission])

        // Line has post-ASCII characters
        body = "Héllo"
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasInvalidUnicodeCharacters])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasInvalidUnicodeCharacters])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [])

        // Line has embedded NUL characters
        body = "Hell\0\n"
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasEmbeddedNul])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [.bodyHasEmbeddedNul])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasEmbeddedNul])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.bodyHasEmbeddedNul])

        // Line has carriage returns
        body = "Hello World!\r\n"
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasRawCarriageReturn])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [.bodyHasRawCarriageReturn])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasRawCarriageReturn])
        XCTAssertEqual(SimpleMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.bodyHasRawCarriageReturn])
    }

    // Test validation on entire messages.
    func testMessageValidation() {
        // Empty message
        var message = SimpleMessage()
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // Empty header
        message.body = "Goodbye, planet.\n"
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // Excessively long body of Unicode characters
        message.body = String(repeating: "é", count: 1000)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertEqual(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.bodyHasInvalidUnicodeCharacters])
        XCTAssertEqual(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError], [.bodyHasLineTooLongForTransmission])
        var errors = Set(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError])
        XCTAssert(errors.contains(.bodyHasInvalidUnicodeCharacters))
        XCTAssert(errors.contains(.bodyHasLineTooLongForTransmission))

        // Empty body
        message.body = nil
        message.header = [SimpleHeaderField(name: "Hello", body: "World"), SimpleHeaderField(name: "Goodbye", body: "planet")]
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false).isEmpty)
        XCTAssertTrue(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true).isEmpty)

        // Problems in header
        message.header[0].body = String(repeating: "d", count: 1000)
        message.header[1].name = "Gøodbyé"
        XCTAssertEqual(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false) as! [InternetMessageError], [.headerFieldNameHasInvalidCharacters])
        XCTAssertEqual(message.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true) as! [InternetMessageError], [.headerFieldNameHasInvalidCharacters])
        errors = Set(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false) as! [InternetMessageError])
        XCTAssert(errors.contains(.headerFieldNameHasInvalidCharacters))
        XCTAssert(errors.contains(.headerFieldCouldNotBeWrappedForTransmission))
        errors = Set(message.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true) as! [InternetMessageError])
        XCTAssert(errors.contains(.headerFieldNameHasInvalidCharacters))
        XCTAssert(errors.contains(.headerFieldCouldNotBeWrappedForTransmission))
    }

    // Test externalization.
    func testMessageSerialization() {
        // Empty message
        var message = SimpleMessage()
        XCTAssertEqual(message.headerAsInternalString, "")
        XCTAssertEqual(message.messageAsInternalString, "")
        XCTAssertEqual(message.messageAsExternalData, Data())

        // Empty body
        message.header.append(SimpleHeaderField(name: "Hello", body: "World"))
        XCTAssertEqual(message.headerAsInternalString, "Hello: World\n")
        XCTAssertEqual(message.messageAsInternalString, "Hello: World\n")
        XCTAssertEqual(message.messageAsExternalData, "Hello: World\r\n".data(using: .utf8))
        message.header.append(SimpleHeaderField(name: "Goodbye", body: "planet"))
        XCTAssertEqual(message.headerAsInternalString, "Hello: World\nGoodbye: planet\n")
        XCTAssertEqual(message.messageAsInternalString, "Hello: World\nGoodbye: planet\n")
        XCTAssertEqual(message.messageAsExternalData, "Hello: World\r\nGoodbye: planet\r\n".data(using: .utf8))

        // Header and body content
        message.body = ""
        XCTAssertEqual(message.headerAsInternalString, "Hello: World\nGoodbye: planet\n")
        XCTAssertEqual(message.messageAsInternalString, "Hello: World\nGoodbye: planet\n\n")
        XCTAssertEqual(message.messageAsExternalData, "Hello: World\r\nGoodbye: planet\r\n\r\n".data(using: .utf8))
        message.body = "Message Test"
        XCTAssertEqual(message.headerAsInternalString, "Hello: World\nGoodbye: planet\n")
        XCTAssertEqual(message.messageAsInternalString, "Hello: World\nGoodbye: planet\n\nMessage Test")
        XCTAssertEqual(message.messageAsExternalData, "Hello: World\r\nGoodbye: planet\r\n\r\nMessage Test".data(using: .utf8))
        message.body = "Message Test\nWorking great!\n"
        XCTAssertEqual(message.headerAsInternalString, "Hello: World\nGoodbye: planet\n")
        XCTAssertEqual(message.messageAsInternalString, "Hello: World\nGoodbye: planet\n\nMessage Test\nWorking great!\n")
        XCTAssertEqual(message.messageAsExternalData, "Hello: World\r\nGoodbye: planet\r\n\r\nMessage Test\r\nWorking great!\r\n".data(using: .utf8))
    }

}

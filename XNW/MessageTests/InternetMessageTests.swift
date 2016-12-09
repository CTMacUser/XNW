//
//  InternetMessageTests.swift
//  XNW
//
//  Created by Daryle Walker on 5/10/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import XCTest
@testable import Message


class InternetMessageTests: XCTestCase {

    struct SimpleInternetMessage: InternetMessage {

        /// No configuration data needed for initialization.
        typealias Configuration = Void

        /// The header section of the message.
        var header: [UnstructuredHeaderField]  // Using `HeaderField` made the computed properties below break.
        /// The body of the message.
        var body: String?

        /// Initializes to empty `header` and absent `body`.
        init(configuration: Configuration) {
            header = []
        }

        /// Transform new field for storage.
        func transformField(sample: ValidatingInitializerHeaderField) -> UnstructuredHeaderField {
            return sample as! UnstructuredHeaderField  // Use inside knowledge of `sample`'s actual type
        }

    }

    func testInitialization() {
        // Default initializer
        let sample = SimpleInternetMessage()
        XCTAssert(sample.header.isEmpty)
        XCTAssertNil(sample.body)
        XCTAssertEqual(sample.messageDescription, "")
    }

    func testDescriptions() {
        // Empty header and body
        var sample = SimpleInternetMessage()
        XCTAssertEqual(sample.messageDescription, "")
        XCTAssertEqual(sample.wrappedDescription, "")
        XCTAssertTrue(sample.binaryDescription!.isEqualToData(NSData()))

        // Header only
        sample.header.append(try! UnstructuredHeaderField(name: "Hello", body: "World"))
        XCTAssertEqual(sample.messageDescription, "Hello: World\n")
        XCTAssertEqual(sample.wrappedDescription, "Hello: World\n")
        XCTAssertEqual(sample.binaryDescription!.swiftData, [72, 101, 108, 108, 111, 58, 32, 87, 111, 114, 108, 100, 13, 10])

        // Body only
        sample.header.removeAll()
        sample.body = "Hello World"
        XCTAssertEqual(sample.messageDescription, "\nHello World")
        XCTAssertEqual(sample.wrappedDescription, "\nHello World")
        XCTAssertEqual(sample.binaryDescription!.swiftData, [13, 10, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])

        // Header and body; excessively long header fields
        let a995 = String(count: 995, repeatedValue: Character("a"))
        let a995Binary = Array<UInt8>(count: a995.characters.count, repeatedValue: a995.utf8.first!)
        sample.header.append(try! UnstructuredHeaderField(name: a995, body: " \t  "))
        sample.header.append(try! UnstructuredHeaderField(name: "bb", body: a995))
        sample.body = "Hello\nThere"
        XCTAssertEqual(sample.messageDescription, "\(a995): \t  \nbb: \(a995)\n\nHello\nThere")
        XCTAssertEqual(sample.wrappedDescription, "\(a995): \t  \nbb:\n \(a995)\n\nHello\nThere")
        var longFieldBinary = a995Binary  // Putting the following expression into the following test-assert with the concatenations inline breaks Xcode's indexer (makes it slow).
        longFieldBinary += [58, 32, 9, 32, 32, 13, 10, 98, 98, 58, 13, 10, 32]
        longFieldBinary += a995Binary
        longFieldBinary += [13, 10, 13, 10, 72, 101, 108, 108, 111, 13, 10, 84, 104, 101, 114, 101]
        XCTAssertEqual(sample.binaryDescription!.swiftData, longFieldBinary)
    }

    func testWidthChecks() {
        // Default-initialized
        var sample = SimpleInternetMessage()
        XCTAssertFalse(sample.headerTooWide)
        XCTAssertFalse(sample.bodyTooWide)
        XCTAssertFalse(sample.tooWide)

        // Normal-length header field and body
        sample.header.append(try! UnstructuredHeaderField(name: "Hello", body: "World"))
        sample.body = "Hello World\n"
        XCTAssertFalse(sample.headerTooWide)
        XCTAssertFalse(sample.bodyTooWide)
        XCTAssertFalse(sample.tooWide)

        // Excessively-wide body
        let a1000 = String(count: 1000, repeatedValue: Character("a"))
        sample.body = a1000
        XCTAssertFalse(sample.headerTooWide)
        XCTAssertTrue(sample.bodyTooWide)
        XCTAssertTrue(sample.tooWide)
        sample.body = "\(a1000)\nbb"
        XCTAssertTrue(sample.bodyTooWide)
        sample.body = "cc\n\(a1000)\nbb"
        XCTAssertTrue(sample.bodyTooWide)

        // Excessively-long header field and body
        sample.header.append(try! UnstructuredHeaderField(name: a1000, body: ""))
        XCTAssertTrue(sample.headerTooWide)
        XCTAssertTrue(sample.bodyTooWide)
        XCTAssertTrue(sample.tooWide)
        // Excessively-long header field
        sample.body = nil
        XCTAssertTrue(sample.headerTooWide)
        XCTAssertFalse(sample.bodyTooWide)
        XCTAssertTrue(sample.tooWide)
    }

    func testBadBodyCharacter() {
        // Default-initialized
        var sample = SimpleInternetMessage()
        XCTAssertFalse(sample.bodyHasBannedCharacters)

        // Empty and normal
        sample.body = ""
        XCTAssertFalse(sample.bodyHasBannedCharacters)
        sample.body = "Hello\n"
        XCTAssertFalse(sample.bodyHasBannedCharacters)  // The "\n" is the line break, so it's ignored.
        // Banned characters (Tests with "\n" get hidden.)
        sample.body = "\0"
        XCTAssertTrue(sample.bodyHasBannedCharacters)
        sample.body = "\n\r"
        XCTAssertTrue(sample.bodyHasBannedCharacters)
        sample.body = "\r\n\0\n"
        XCTAssertTrue(sample.bodyHasBannedCharacters)
    }

    func testParsingInitialization() {
        // No message data
        let sample1 = SimpleInternetMessage(string: "")
        XCTAssertTrue(sample1.header.isEmpty)
        XCTAssertNil(sample1.body)

        // Single header field, without and with line-terminator
        let sample2 = SimpleInternetMessage(string: "Hello: World")
        XCTAssertEqual(sample2.header.count, 1)
        XCTAssertEqual(sample2.header.first!.name, "Hello")
        XCTAssertEqual(sample2.header.first!.body, " World")
        XCTAssertNil(sample2.body)
        let sample3 = SimpleInternetMessage(string: "Hello: World\n")
        XCTAssertEqual(sample3.header.count, 1)
        XCTAssertEqual(sample3.header.first!.name, "Hello")
        XCTAssertEqual(sample3.header.first!.body, " World")
        XCTAssertNil(sample3.body)

        // Single-line body, without and with various line terminators (The various terminators all get stored as "\n".)
        let sample4 = SimpleInternetMessage(string: "Hello World")
        XCTAssertTrue(sample4.header.isEmpty)
        XCTAssertNotNil(sample4.body)
        XCTAssertEqual(sample4.body!, "Hello World")
        let sample5 = SimpleInternetMessage(string: "Hello World\n")
        XCTAssertTrue(sample5.header.isEmpty)
        XCTAssertNotNil(sample5.body)
        XCTAssertEqual(sample5.body!, "Hello World\n")
        let sample6 = SimpleInternetMessage(string: "Hello World\r")
        XCTAssertTrue(sample6.header.isEmpty)
        XCTAssertNotNil(sample6.body)
        XCTAssertEqual(sample6.body!, "Hello World\n")
        let sample7 = SimpleInternetMessage(string: "Hello World\r\n")
        XCTAssertTrue(sample7.header.isEmpty)
        XCTAssertNotNil(sample7.body)
        XCTAssertEqual(sample7.body!, "Hello World\n")
        let sample8 = SimpleInternetMessage(string: "Hello World\n\r")
        XCTAssertTrue(sample8.header.isEmpty)
        XCTAssertNotNil(sample8.body)
        XCTAssertEqual(sample8.body!, "Hello World\n\n")

        // Header with all-blank line, continuation line, space before colon; blank line between header and body.
        let sample9 = SimpleInternetMessage(string: "Hello: There\n\t\n World\nGoodbye :Planet\n\nTests.")
        XCTAssertEqual(sample9.header.count, 2)
        XCTAssertEqual(sample9.header.first!.name, "Hello")
        XCTAssertEqual(sample9.header.first!.body, " There\t World")
        XCTAssertEqual(sample9.header.last!.name, "Goodbye")
        XCTAssertEqual(sample9.header.last!.body, "Planet")
        XCTAssertNotNil(sample9.body)
        XCTAssertEqual(sample9.body, "Tests.")
        // Header continuation line starting string (counts as header-less message)
        let sample10 = SimpleInternetMessage(string: " Space-led\nHeader: Backwards")
        XCTAssertTrue(sample10.header.isEmpty)
        XCTAssertNotNil(sample10.body)
        XCTAssertEqual(sample10.body, " Space-led\nHeader: Backwards")
        // Header field with bad name (internal space), counts as non-header line
        let sample11 = SimpleInternetMessage(string: "Bad Name: Whatever\r")
        XCTAssertTrue(sample11.header.isEmpty)
        XCTAssertNotNil(sample11.body)
        XCTAssertEqual(sample11.body, "Bad Name: Whatever\n")
        // Header field with Apple-only line breaks
        let sample12 = SimpleInternetMessage(string: "Hello: World\u{85}There: Is\n")
        XCTAssertEqual(sample12.header.count, 1)  // Not 2
        XCTAssertEqual(sample12.header.first?.name, "Hello")
        XCTAssertEqual(sample12.header.first?.body, " World\u{85}There: Is")
        XCTAssertNil(sample12.body)
    }

    func testDataInitialization() {
        // Use default conversion encodings.
        let badHeader = "Héllo: World"  // Can't be a header field due to second character.
        let badHeaderData = badHeader.dataUsingEncoding(NSUTF8StringEncoding)!
        let sample1 = SimpleInternetMessage(data: badHeaderData)
        XCTAssertNotNil(sample1)
        XCTAssertTrue(sample1!.header.isEmpty)
        XCTAssertEqual(sample1!.body, badHeader)

        // Now restrict encodings used to not accept one of the characters.
        let sample2 = SimpleInternetMessage(data: badHeaderData, encodings: [NSNonLossyASCIIStringEncoding])
        XCTAssertNil(sample2)
    }

}

extension NSData {
    
    /// As a more Swift-like type
    var swiftData: [UInt8] {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(self.bytes), count: self.length))
    }
    
}

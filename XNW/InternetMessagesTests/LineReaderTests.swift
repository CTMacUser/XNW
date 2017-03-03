//
//  LineReaderTests.swift
//  XNW
//
//  Created by Daryle Walker on 2/24/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import XCTest
@testable import InternetMessages


class LineReaderTests: XCTestCase {

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

    // Test data-block iteration.
    func testDataBlockIterator() {
        // Data that fits the block size
        let sample = Data(bytes: [0, 1, 2, 3, 4, 5])
        var iterateBy2 = DataBlockIterator(data: sample, blockSize: 2)
        XCTAssertEqual(iterateBy2.next(), Data(bytes: [0, 1]))
        XCTAssertEqual(iterateBy2.next(), Data(bytes: [2, 3]))
        XCTAssertEqual(iterateBy2.next(), Data(bytes: [4, 5]))
        XCTAssertNil(iterateBy2.next())

        // Data that doesn't evenly fit the block size
        var iterateBy4 = DataBlockIterator(data: sample, blockSize: 4)
        XCTAssertEqual(iterateBy4.next(), Data(bytes: [0, 1, 2, 3]))
        XCTAssertEqual(iterateBy4.next(), Data(bytes: [4, 5]))
        XCTAssertNil(iterateBy4.next())

        // No data
        var iteratorNone = DataBlockIterator(data: Data(), blockSize: 1)
        XCTAssertNil(iteratorNone.next())
    }

    // Test line iteration over data blocks, all within a single block.
    func testBasicDataInternetLineIterator() {
        // No data
        var iteratorNone = DataInternetLineIterator(data: Data())
        XCTAssertNil(iteratorNone.next())

        // No terminator
        let mary = LineReaderTests.mary
        let sampleOneUnterminatedLine = mary.first!.data(using: .utf8)!
        var iterator1UL = DataInternetLineIterator(data: sampleOneUnterminatedLine)
        var location = iterator1UL.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, mary.first!.utf8.count)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(iterator1UL.next())

        // Single terminated line
        var iterator1TL = DataInternetLineIterator(data: sampleOneUnterminatedLine + "\n".data(using: .utf8)!)
        location = iterator1TL.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, sampleOneUnterminatedLine.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(iterator1UL.next())

        iterator1TL = DataInternetLineIterator(data: sampleOneUnterminatedLine + "\r".data(using: .utf8)!)
        location = iterator1TL.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, sampleOneUnterminatedLine.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(iterator1UL.next())

        iterator1TL = DataInternetLineIterator(data: sampleOneUnterminatedLine + "\r\n".data(using: .utf8)!)
        location = iterator1TL.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, sampleOneUnterminatedLine.count + 2)
        XCTAssertEqual(location?.terminatorLength, 2)
        XCTAssertNil(iterator1UL.next())

        iterator1TL = DataInternetLineIterator(data: sampleOneUnterminatedLine + "\r\r\n".data(using: .utf8)!)
        location = iterator1TL.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, sampleOneUnterminatedLine.count + 3)
        XCTAssertEqual(location?.terminatorLength, 3)
        XCTAssertNil(iterator1UL.next())

        // Multiple lines, first checking that CR-CRLF doesn't go further, so there's only one more line and it's blank
        var iterator2TL = DataInternetLineIterator(data: sampleOneUnterminatedLine + "\r\r\r\n".data(using: .utf8)!)
        location = iterator2TL.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, sampleOneUnterminatedLine.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iterator2TL.next()
        XCTAssertEqual(location?.indices.lowerBound, sampleOneUnterminatedLine.count + 1)
        XCTAssertEqual(location?.indices.count, 3)
        XCTAssertEqual(location?.terminatorLength, 3)
        XCTAssertNil(iterator2TL.next())

        // Multiple lines
        let poem = (mary[0] + "\r\r\n" + mary[1] + "\n" + mary[2] + "\r" + mary[3]).data(using: .utf8)!
        var iteratorPoem = DataInternetLineIterator(data: poem)
        location = iteratorPoem.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, mary[0].utf8.count + 3)
        XCTAssertEqual(location?.terminatorLength, 3)
        location = iteratorPoem.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[0].utf8.count + 3)
        XCTAssertEqual(location?.indices.count, mary[1].utf8.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[0].utf8.count + 3 + mary[1].utf8.count + 1)
        XCTAssertEqual(location?.indices.count, mary[2].utf8.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[0].utf8.count + 3 + mary[1].utf8.count + 1 + mary[2].utf8.count + 1)
        XCTAssertEqual(location?.indices.count, mary[3].utf8.count)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(iteratorPoem.next())

        // Multiple lines, with accidental LFCR pair
        let poem2 = (mary[3] + "\n\r" + mary[1] + "\r\n").data(using: .utf8)!
        var iteratorPoem2 = DataInternetLineIterator(data: poem2)
        location = iteratorPoem2.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, mary[3].utf8.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem2.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[3].utf8.count + 1)
        XCTAssertEqual(location?.indices.count, 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem2.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[3].utf8.count + 1 + 1)
        XCTAssertEqual(location?.indices.count, mary[1].utf8.count + 2)
        XCTAssertEqual(location?.terminatorLength, 2)
        XCTAssertNil(iteratorPoem2.next())

        // CR-XX-LF, where XX is not CR
        let poem3 = (mary[2] + "\rX\n").data(using: .utf8)!
        var iteratorPoem3 = DataInternetLineIterator(data: poem3)
        location = iteratorPoem3.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, mary[2].utf8.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem3.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[2].utf8.count + 1)
        XCTAssertEqual(location?.indices.count, 2)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(iteratorPoem3.next())

        // Multiple lines from mistaken LFCR
        let poem4 = (mary[1] + "\n\r").data(using: .utf8)!
        var iteratorPoem4 = DataInternetLineIterator(data: poem4)
        location = iteratorPoem4.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, mary[1].utf8.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem4.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[1].utf8.count + 1)
        XCTAssertEqual(location?.indices.count, 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(iteratorPoem4.next())

        // Multiple lines from CR, especially two in a row at the end
        let poem5 = (mary[0] + "\r\r").data(using: .utf8)!
        var iteratorPoem5 = DataInternetLineIterator(data: poem5)
        location = iteratorPoem5.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, mary[0].utf8.count + 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = iteratorPoem5.next()
        XCTAssertEqual(location?.indices.lowerBound, mary[0].utf8.count + 1)
        XCTAssertEqual(location?.indices.count, 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(iteratorPoem5.next())
    }

    // Test line iteration over data blocks, all across multiple blocks.
    func testAdvancedDataInternetLineIterator() {
        // Two blocks, no terminator
        let twoBlocksNoTerm = "12345678901234567890".data(using: .utf8)!
        var lineIterator = DataInternetLineIterator(data: twoBlocksNoTerm, blockSize: 10)
        var location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 20)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        // 1.5 blocks, no terminator
        lineIterator = DataInternetLineIterator(data: "123456789012345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 15)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        // 1.5 blocks, various terminators
        lineIterator = DataInternetLineIterator(data: "12345678901234\n".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 15)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "12345678901234\r".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 15)
        XCTAssertEqual(location?.terminatorLength, 1)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "1234567890123\r\n".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 15)
        XCTAssertEqual(location?.terminatorLength, 2)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "123456789012\r\r\n".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 15)
        XCTAssertEqual(location?.terminatorLength, 3)
        XCTAssertNil(lineIterator.next())

        // 3 blocks, various terminators at end of second block
        lineIterator = DataInternetLineIterator(data: "1234567890123456789\n12345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 20)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 20)
        XCTAssertEqual(location?.indices.count, 5)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "1234567890123456789\r12345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 20)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 20)
        XCTAssertEqual(location?.indices.count, 5)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "123456789012345678\r\n12345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 20)
        XCTAssertEqual(location?.terminatorLength, 2)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 20)
        XCTAssertEqual(location?.indices.count, 5)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "12345678901234567\r\r\n12345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 20)
        XCTAssertEqual(location?.terminatorLength, 3)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 20)
        XCTAssertEqual(location?.indices.count, 5)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "123456789012345678\r\r12345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 19)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 19)
        XCTAssertEqual(location?.indices.count, 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 20)
        XCTAssertEqual(location?.indices.count, 5)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        // 2 blocks, split terminators on boundary
        lineIterator = DataInternetLineIterator(data: "12345678\r\r\n2345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 11)
        XCTAssertEqual(location?.terminatorLength, 3)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 11)
        XCTAssertEqual(location?.indices.count, 4)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "123456789\r\r\n345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 12)
        XCTAssertEqual(location?.terminatorLength, 3)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 12)
        XCTAssertEqual(location?.indices.count, 3)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "123456789\r\n2345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 11)
        XCTAssertEqual(location?.terminatorLength, 2)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 11)
        XCTAssertEqual(location?.indices.count, 4)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        // 3 blocks, various terminators at start of third block
        lineIterator = DataInternetLineIterator(data: "12345678901234567890\n2345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 21)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 21)
        XCTAssertEqual(location?.indices.count, 4)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "12345678901234567890\r2345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 21)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 21)
        XCTAssertEqual(location?.indices.count, 4)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "12345678901234567890\r\n345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 22)
        XCTAssertEqual(location?.terminatorLength, 2)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 22)
        XCTAssertEqual(location?.indices.count, 3)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "12345678901234567890\r\r\n45".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 23)
        XCTAssertEqual(location?.terminatorLength, 3)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 23)
        XCTAssertEqual(location?.indices.count, 2)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        lineIterator = DataInternetLineIterator(data: "12345678901234567890\r\r345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 21)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 21)
        XCTAssertEqual(location?.indices.count, 1)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 22)
        XCTAssertEqual(location?.indices.count, 3)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())

        // Extra case with CR-CR ending a block, but leads to CRLF on other side -> CR | CR-CRLF
        lineIterator = DataInternetLineIterator(data: "12345678\r\r\r\n345".data(using: .utf8)!, blockSize: 10)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 0)
        XCTAssertEqual(location?.indices.count, 9)
        XCTAssertEqual(location?.terminatorLength, 1)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 9)
        XCTAssertEqual(location?.indices.count, 3)
        XCTAssertEqual(location?.terminatorLength, 3)
        location = lineIterator.next()
        XCTAssertEqual(location?.indices.lowerBound, 12)
        XCTAssertEqual(location?.indices.count, 3)
        XCTAssertEqual(location?.terminatorLength, 0)
        XCTAssertNil(lineIterator.next())
    }

    // Test getting lines from data
    func testLineReading() {
        let a999 = String(repeating: "a", count: 999)
        let b999 = String(repeating: "b", count: 999)
        let c998 = String(repeating: "c", count: 998)
        let d997 = String(repeating: "d", count: 997)
        let e1000 = String(repeating: "e", count: 1000)
        let text = a999 + "\n" + b999 + "\r" + c998 + "\r\n" + d997 + "\r\r\n" + e1000
        var reader = LineReader(data: text.data(using: .utf8)!)

        // Test with the iterator interface
        XCTAssertEqual(reader.blockSize, 4096)
        XCTAssertGreaterThan(text.utf8.count, reader.blockSize)
        XCTAssertEqual(reader.data, text.data(using: .utf8))
        XCTAssertNil(reader.previousHadTerminator)
        XCTAssertEqual(reader.next(), a999)
        XCTAssertEqual(reader.previousHadTerminator, true)
        XCTAssertEqual(reader.next(), b999)
        XCTAssertEqual(reader.previousHadTerminator, true)
        XCTAssertEqual(reader.next(), c998)
        XCTAssertEqual(reader.previousHadTerminator, true)
        XCTAssertEqual(reader.next(), d997)
        XCTAssertEqual(reader.previousHadTerminator, true)
        XCTAssertEqual(reader.next(), e1000)
        XCTAssertEqual(reader.previousHadTerminator, false)
        XCTAssertNil(reader.next())

        // Test with the sequence interface
        XCTAssertEqual(Array(LineReader(data: text.data(using: .utf8)!)), [a999, b999, c998, d997, e1000])
    }

}

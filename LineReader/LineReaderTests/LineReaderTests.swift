//
//  LineReaderTests.swift
//  LineReaderTests
//
//  Created by Daryle Walker on 3/10/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import XCTest
import Foundation
@testable import LineReader


class LineReaderTests: XCTestCase {

    var dataLF: NSData?
    var dataCR: NSData?
    var dataCRLF: NSData?

    override func setUp() {
        super.setUp()

        dataLF = NSData(bytes: [UInt8(10)], length: 1)
        dataCR = NSData(bytes: [UInt8(13)], length: 1)
        dataCRLF = NSData(bytes: [UInt8(13), UInt8(10)], length: 2)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // No terminators
    func testNoTerms() {
        let reader = LineReader(lineTerminators: Set())
        XCTAssertEqual(reader.parseTree.followupSymbols, Set())
        XCTAssertEqual(reader.terminators, Set())
    }

    // No-byte "terminator"
    func testEmptyTerm() {
        let reader = LineReader(lineTerminators: Set(arrayLiteral: NSData()))
        XCTAssertEqual(reader.parseTree.followupSymbols, Set())
        XCTAssertEqual(reader.terminators, Set())  // Breaks the usual assumption!
    }

    // One-byte terminator
    func testOneTermOneByte() {
        let reader = LineReader(lineTerminators: Set([dataLF!]))
        XCTAssertEqual(reader.parseTree.followupSymbols, Set([10]))
        XCTAssertNotNil(reader.parseTree.followerUsing(10))
        XCTAssertEqual(reader.terminators, Set([dataLF!]))
    }

    func testTwoTermsOneByteNoOverlap() {
        let reader = LineReader(lineTerminators: Set([dataLF!, dataCR!]))
        XCTAssertEqual(reader.parseTree.followupSymbols, Set([10, 13]))
        XCTAssertNotNil(reader.parseTree.followerUsing(10))
        XCTAssertNotNil(reader.parseTree.followerUsing(13))
        XCTAssertNil(reader.parseTree.followerUsing(13)?.followerUsing(10))
        XCTAssertEqual(reader.terminators, Set([dataLF!, dataCR!]))
    }

    // Multi-byte terminator
    func testOneTermTwoBytes() {
        let reader = LineReader(lineTerminators: Set([dataCRLF!]))
        XCTAssertEqual(reader.parseTree.followupSymbols, Set([13]))
        XCTAssertNil(reader.parseTree.followerUsing(10))
        XCTAssertNotNil(reader.parseTree.followerUsing(13))
        XCTAssertNotNil(reader.parseTree.followerUsing(13)?.followerUsing(10))
        XCTAssertEqual(reader.terminators, Set([dataCRLF!]))
    }

    func testTwoTermsMixedSizeNoInitialOverlap() {
        let reader = LineReader(lineTerminators: Set([dataLF!, dataCRLF!]))
        XCTAssertEqual(reader.parseTree.followupSymbols, Set([10, 13]))
        XCTAssertNotNil(reader.parseTree.followerUsing(10))
        XCTAssertNotNil(reader.parseTree.followerUsing(13))
        XCTAssertNotNil(reader.parseTree.followerUsing(13)?.followerUsing(10))
        XCTAssertEqual(reader.terminators, Set([dataLF!, dataCRLF!]))
    }

    func testTwoTermsMixedSizeWithInitialOverlap() {
        let reader = LineReader(lineTerminators: Set([dataCR!, dataCRLF!]))
        XCTAssertEqual(reader.parseTree.followupSymbols, Set([13]))
        XCTAssertNil(reader.parseTree.followerUsing(10))
        XCTAssertNotNil(reader.parseTree.followerUsing(13))
        XCTAssertNotNil(reader.parseTree.followerUsing(13)?.followerUsing(10))
        XCTAssertEqual(reader.terminators, Set([dataCR!, dataCRLF!]))
    }

}

//
//  HeaderFieldBodyFragmentTests.swift
//  XNW
//
//  Created by Daryle Walker on 5/25/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import XCTest
@testable import Message


class HeaderFieldBodyFragmentTests: XCTestCase {

    func testInitializationAndFragmentsAndDescriptions() {
        // Check strings that can't get past initializer.
        let sample1 = HeaderFieldBodyFragment(single: "")
        XCTAssertNil(sample1)
        let sample2 = HeaderFieldBodyFragment(single: "NonSpace")
        XCTAssertNil(sample2)

        // And a quirkly case that does.  Check the most basic inspector.
        let sample3 = HeaderFieldBodyFragment(single: "  ")
        XCTAssertNotNil(sample3)
        XCTAssertEqual(sample3!.fragments, ["  "])
        XCTAssertEqual(sample3!.description, "  ")
        // A normal case.
        let sample4 = HeaderFieldBodyFragment(single: " Hello")
        XCTAssertNotNil(sample4)
        XCTAssertEqual(sample4!.fragments, [" Hello"])
        XCTAssertEqual(sample4!.description, " Hello")

        // Build from groups of fragments
        let samples = [
            HeaderFieldBodyFragment(single: " World")!,
            HeaderFieldBodyFragment(single: " There")!
        ]
        let sample5 = HeaderFieldBodyFragment(group: samples)  // array-bundled fragments
        XCTAssertEqual(sample5.fragments, [" World", " There"])
        XCTAssertEqual(sample5.description, " World There")
        let sample6 = HeaderFieldBodyFragment(fragments: samples[1], samples[0])  // free-listed fragments
        XCTAssertEqual(sample6.fragments, [" There", " World"])
        XCTAssertEqual(sample6.description, " There World")
        let sample7 = HeaderFieldBodyFragment()  // No fragments
        XCTAssertEqual(sample7.fragments, [])
        XCTAssertEqual(sample7.description, "")
        let sample8 = HeaderFieldBodyFragment(fragments: sample4!)  // a single nested fragment
        XCTAssertEqual(sample8.fragments, [" Hello"])
        XCTAssertEqual(sample8.description, " Hello")
        let sample9 = HeaderFieldBodyFragment(group: [sample8, sample6])  // multiple group-based fragments
        XCTAssertEqual(sample9.fragments, [" Hello", " There", " World"])
        XCTAssertEqual(sample9.description, " Hello There World")
    }

    func testWrappedDescriptions() {
        let sample1 = HeaderFieldBodyFragment(single: " Hello")!
        let sample2 = HeaderFieldBodyFragment(single: " There")!
        let sample3 = HeaderFieldBodyFragment(single: " World")!
        let sample4 = HeaderFieldBodyFragment()
        let sample5 = HeaderFieldBodyFragment(single: "\t")!
        XCTAssertEqual(sample1.descriptionAppendedTo("What:", softCutoff: 0), "What:\n Hello")
        XCTAssertEqual(sample4.descriptionAppendedTo("What:", softCutoff: 0), "What:")
        XCTAssertEqual(sample5.descriptionAppendedTo("What:", softCutoff: 0), "What:\t")
        let sample6 = HeaderFieldBodyFragment(fragments: sample1, HeaderFieldBodyFragment(fragments: sample2, sample3))
        XCTAssertEqual(sample6.descriptionAppendedTo("What:", softCutoff: 0), "What:\n Hello\n There\n World")
        XCTAssertEqual(sample6.descriptionAppendedTo("What:", softCutoff: 100), "What: Hello There World")
        XCTAssertEqual(sample6.descriptionAppendedTo("What:", softCutoff: 10), "What:\n Hello\n There\n World")
        XCTAssertEqual(sample6.descriptionAppendedTo("What:", softCutoff: 12), "What: Hello\n There World")
    }

    func testAllWhitespace() {
        let sample1 = HeaderFieldBodyFragment(single: " ")!
        let sample2 = HeaderFieldBodyFragment(single: " Not All Whitespace")!
        let sample3 = HeaderFieldBodyFragment()
        XCTAssertEqual(sample1.allWhitespaceStart, " ")
        XCTAssertNil(sample2.allWhitespaceStart)
        XCTAssertNil(sample3.allWhitespaceStart)

        let sample4 = HeaderFieldBodyFragment(fragments: sample1, sample2, sample3)
        XCTAssertEqual(sample4.allWhitespaceStart, " ")
        let sample5 = HeaderFieldBodyFragment(fragments: HeaderFieldBodyFragment(fragments: sample1, sample2), sample3)
        XCTAssertEqual(sample5.allWhitespaceStart, " ")
        let sample6 = HeaderFieldBodyFragment(group: [sample2, sample1])
        XCTAssertNil(sample6.allWhitespaceStart)
    }

    func testFragmentLength() {
        let sample1 = HeaderFieldBodyFragment(single: "\t")!
        let sample2 = HeaderFieldBodyFragment(single: " Some non-space")!
        let sample3 = HeaderFieldBodyFragment()
        XCTAssertEqual(sample1.maximumFragmentLength, 1)
        XCTAssertEqual(sample2.maximumFragmentLength, 15)
        XCTAssertEqual(sample3.maximumFragmentLength, 0)

        let sample4 = HeaderFieldBodyFragment(fragments: sample1, sample3, sample2)
        XCTAssertEqual(sample4.maximumFragmentLength, 15)
        let sample5 = HeaderFieldBodyFragment(group: [sample3, HeaderFieldBodyFragment(fragments: sample2, sample1)])
        XCTAssertEqual(sample5.maximumFragmentLength, 15)
        let sample6 = HeaderFieldBodyFragment(fragments: HeaderFieldBodyFragment(group: [sample3]))
        XCTAssertEqual(sample6.maximumFragmentLength, 0)
    }

}

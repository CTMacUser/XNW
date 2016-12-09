//
//  HeaderFieldTests.swift
//  XNW
//
//  Created by Daryle Walker on 5/2/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import XCTest
@testable import Message
import Foundation


class HeaderFieldTests: XCTestCase {

    func testInitialization() {
        let sample: HeaderField = try! UnstructuredHeaderField(name: "Hello", body: "World")
        XCTAssertEqual(sample.name, "Hello")
        XCTAssertEqual(sample.body, "World")
        XCTAssertTrue(sample.meetsFieldInvariants)

        let badBody = "Bad\0Format"
        let samples = [
            try? UnstructuredHeaderField(name: "Big:Colon", body: ""),  // 0
            try? UnstructuredHeaderField(name: "", body: ""),  // 1
            try? UnstructuredHeaderField(name: String(count: 997, repeatedValue: Character("a")), body: ""),  // 2
            try? UnstructuredHeaderField(name: String(count: 999, repeatedValue: Character("b")), body: ""),  // 3
            try? UnstructuredHeaderField(name: "Hi", body: badBody),  // 4
            try? UnstructuredHeaderField(name: "Hi", body: "good"),  // 5
            try? UnstructuredHeaderField(name: "Hi", body: ""),  // 6
            try? UnstructuredHeaderField(name: "Hi", body: String(count: 997, repeatedValue: Character("c"))),  // 7
            try? UnstructuredHeaderField(name: "Hi", body: String(count: 999, repeatedValue: Character("d"))),  // 8
        ]
        XCTAssertNil(samples[0])
        XCTAssertNil(samples[1])
        XCTAssertNotNil(samples[2])
        XCTAssertNotNil(samples[3])  // Length (overage) check moved out of initialization phase
        XCTAssertFalse(UnstructuredHeaderField.problemsValidatingBody(badBody).isEmpty)
        XCTAssertNotNil(samples[4])
        XCTAssertNotEqual(samples[4]!.body, badBody)
        XCTAssertNotNil(samples[5])
        XCTAssertNotNil(samples[6])
        XCTAssertNotNil(samples[7])
        XCTAssertNotNil(samples[8])  // Length check moved out of initialization phase
        XCTAssertEqual(samples.filter { $0?.meetsFieldInvariants ?? false }.count, 7)
    }

    func testDescriptions() {
        var sample = try! UnstructuredHeaderField(name: "Hello", body: "World")
        XCTAssertEqual(sample.preface, "Hello:")
        XCTAssertEqual(sample.postface, " World")
        XCTAssertEqual(sample.wrappedPostface, " World\n")
        XCTAssertEqual(sample.fieldDescription, "Hello: World")
        XCTAssertEqual(sample.wrappedDescription, "Hello: World\n")
        XCTAssertFalse(sample.tooLong)

        sample = try! UnstructuredHeaderField(name: sample.name, body: " There")
        XCTAssertEqual(sample.postface, " There")  // Doesn't add another space
        XCTAssertEqual(sample.fieldDescription, "Hello: There")
        XCTAssertEqual(sample.wrappedDescription, "Hello: There\n")
        XCTAssertFalse(sample.tooLong)

        let e85 = String(count: InternetMessageConstants.preferredMaximumLineCharacterLength + 7, repeatedValue: Character("e"))
        sample = try! UnstructuredHeaderField(name: sample.name, body: e85)
        XCTAssertEqual(sample.postface, " \(e85)")
        XCTAssertEqual(sample.fieldDescription, "Hello: \(e85)")
        XCTAssertEqual(sample.wrappedDescription, "Hello:\n \(e85)\n")
        XCTAssertFalse(sample.tooLong)

        sample = try! UnstructuredHeaderField(name: e85, body: "  Woah!")  // Starts with 2 spaces
        XCTAssertEqual(sample.preface, "\(e85):")
        XCTAssertEqual(sample.postface, sample.body)
        XCTAssertEqual(sample.fieldDescription, "\(e85):\(sample.body)")
        XCTAssertEqual(sample.wrappedDescription, "\(e85):\n\(sample.body)\n")
        XCTAssertFalse(sample.tooLong)
        let space = Character(" ")
        sample = try! UnstructuredHeaderField(name: sample.name, body: String(count: 1000, repeatedValue: space) + "Woah!")
        XCTAssertEqual(sample.fieldDescription, "\(e85):\(sample.body)")
        XCTAssertEqual(sample.wrappedDescription, "\(e85):\n" + String(count: 1000, repeatedValue: space) + "Woah!\n")
        XCTAssertTrue(sample.tooLong)

        sample = try! UnstructuredHeaderField(name: "Hello", body: "Goodbye" + String(count: 2, repeatedValue: space))
        XCTAssertEqual(sample.fieldDescription, "Hello: Goodbye  ")
        XCTAssertEqual(sample.wrappedDescription, "Hello: Goodbye  \n")
        XCTAssertFalse(sample.tooLong)
        sample = try! UnstructuredHeaderField(name: "Hello", body: "Goodbye" + String(count: 1000, repeatedValue: space))
        XCTAssertEqual(sample.fieldDescription, "Hello: Goodbye" + String(count: 1000, repeatedValue: space))
        XCTAssertEqual(sample.wrappedDescription, "Hello:\n Goodbye" + String(count: 1000, repeatedValue: space) + "\n")
        XCTAssertTrue(sample.tooLong)

        sample = try! UnstructuredHeaderField(name: "Nothing", body: "")
        XCTAssertEqual(sample.fieldDescription, "Nothing:")
        XCTAssertEqual(sample.wrappedDescription, "Nothing:\n")
        XCTAssertFalse(sample.tooLong)
        sample = try! UnstructuredHeaderField(name: "Whitespace", body: " \t ")
        XCTAssertEqual(sample.fieldDescription, "Whitespace: \t ")
        XCTAssertEqual(sample.wrappedDescription, "Whitespace: \t \n")
        XCTAssertFalse(sample.tooLong)

        let f995 = String(count: 995, repeatedValue: Character("f"))
        sample = try! UnstructuredHeaderField(name: f995, body: "")
        XCTAssertEqual(sample.fieldDescription, f995 + ":")
        XCTAssertEqual(sample.wrappedDescription, f995 + ":\n")
        XCTAssertFalse(sample.tooLong)
        sample = try! UnstructuredHeaderField(name: f995, body: " \t  ")
        XCTAssertEqual(sample.fieldDescription, f995 + ": \t  ")
        XCTAssertEqual(sample.wrappedDescription, f995 + ": \t  \n")
        XCTAssertTrue(sample.tooLong)
    }

}

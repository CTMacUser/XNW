//
//  ParseNodeTests.swift
//  LineReader
//
//  Created by Daryle Walker on 3/11/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import XCTest
@testable import LineReader
import Foundation


class ParseNodeTests: XCTestCase {

    var randomByte: UInt8?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.randomByte = UInt8(arc4random_uniform(256))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

    // Check the initializer.
    func testInitialization() {
        let parseNode = ParseNode(symbol: self.randomByte!)
        XCTAssertNil(parseNode.previous)
        XCTAssertEqual(self.randomByte, parseNode.symbol)
        XCTAssertFalse(parseNode.isTerminal)
        XCTAssertTrue(parseNode.next.isEmpty)
    }

    // Check other properties on initialization.
    func testInitializedProperties() {
        let parseNode = ParseNode(symbol: self.randomByte!)
        XCTAssertTrue(parseNode.isLeaf)
        XCTAssertTrue(parseNode.isRoot)
        XCTAssertFalse(parseNode.treeIsProperlyTerminated())
        XCTAssertTrue(parseNode.linksAreConsistent())
        XCTAssertFalse(parseNode.follows(parseNode))
        XCTAssertTrue(parseNode.terminals().isEmpty)
    }

    // Link tests
    func testUnfollowNothing() {
        let parseNode = ParseNode(symbol: self.randomByte!)
        XCTAssertNil(parseNode.unfollow())
    }

    func testBasicLinkAndUnlink() {
        let nodeA = ParseNode(symbol: 2), nodeB = ParseNode(symbol: 3)
        XCTAssertFalse(nodeA.follows(nodeB))
        XCTAssertFalse(nodeB.follows(nodeA))

        let (oldPreviousOfB, ejectedNextFromA) = nodeB.follow(nodeA)
        XCTAssertNil(oldPreviousOfB)
        XCTAssertNil(ejectedNextFromA)
        XCTAssert(nodeB.previous === nodeA)
        XCTAssert(nodeA.next[nodeB.symbol] === nodeB)
        XCTAssertFalse(nodeA.follows(nodeB))
        XCTAssertTrue(nodeB.follows(nodeA))
        XCTAssertFalse(nodeA.isLeaf)
        XCTAssertFalse(nodeB.isRoot)
        XCTAssertTrue(nodeA.linksAreConsistent())
        XCTAssertTrue(nodeB.linksAreConsistent())

        let anotherOldPreviousOfB = nodeB.unfollow()
        XCTAssert(anotherOldPreviousOfB === nodeA)
        XCTAssertFalse(nodeA.follows(nodeB))
        XCTAssertFalse(nodeB.follows(nodeA))
        XCTAssert(nodeB.previous !== nodeA)
        XCTAssert(nodeA.next[nodeB.symbol] !== nodeB)
        XCTAssertTrue(nodeA.isLeaf)
        XCTAssertTrue(nodeB.isRoot)
        XCTAssertTrue(nodeA.linksAreConsistent())
        XCTAssertTrue(nodeB.linksAreConsistent())
    }

    func testBasicChain() {
        let nodeA = ParseNode(symbol: 5), nodeB = ParseNode(symbol: 7), nodeC = ParseNode(symbol: 11)
        XCTAssert(nodeA.isRoot && nodeA.isLeaf)
        XCTAssert(nodeB.isRoot && nodeB.isLeaf)
        XCTAssert(nodeC.isRoot && nodeC.isLeaf)

        let (oldPreviousOfB, ejectedNextFromA) = nodeB.follow(nodeA)
        let (oldPreviousOfC, ejectedNextFromB) = nodeC.follow(nodeB)
        XCTAssertNil(oldPreviousOfB)
        XCTAssertNil(ejectedNextFromA)
        XCTAssertNil(oldPreviousOfC)
        XCTAssertNil(ejectedNextFromB)
        XCTAssertTrue(nodeB.follows(nodeA))
        XCTAssertTrue(nodeC.follows(nodeB))
        XCTAssertTrue(nodeC.follows(nodeA))
        XCTAssert(!nodeB.isRoot && !nodeB.isLeaf)
        XCTAssertTrue(nodeA.linksAreConsistent())
        XCTAssertTrue(nodeB.linksAreConsistent())
        XCTAssertTrue(nodeC.linksAreConsistent())

        let anotherOldPreviousOfC = nodeC.unfollow()
        XCTAssert(anotherOldPreviousOfC === nodeB)
        XCTAssertFalse(nodeC.follows(nodeA))
        XCTAssertTrue(nodeC.isRoot)
        XCTAssertTrue(nodeA.linksAreConsistent())
        XCTAssertTrue(nodeB.linksAreConsistent())
        XCTAssertTrue(nodeC.linksAreConsistent())
    }

    func testMultipleDirectFollowers() {
        let nodeA = ParseNode(symbol: 13), nodeB = ParseNode(symbol: 17), nodeC = ParseNode(symbol: 19)
        XCTAssert(nodeA.isRoot && nodeA.isLeaf)
        XCTAssert(nodeB.isRoot && nodeB.isLeaf)
        XCTAssert(nodeC.isRoot && nodeC.isLeaf)

        let (oldPreviousOfB, ejectedNextFromA) = nodeB.follow(nodeA)
        let (oldPreviousOfC, ejectedNextFromB) = nodeC.follow(nodeA)
        XCTAssertNil(oldPreviousOfB)
        XCTAssertNil(ejectedNextFromA)
        XCTAssertNil(oldPreviousOfC)
        XCTAssertNil(ejectedNextFromB)
        XCTAssertTrue(nodeB.follows(nodeA))
        XCTAssertTrue(nodeC.follows(nodeA))
        XCTAssertFalse(nodeC.follows(nodeB))
        XCTAssert(nodeA.isRoot && !nodeA.isLeaf)
        XCTAssert(!nodeB.isRoot && nodeB.isLeaf)
        XCTAssert(!nodeC.isRoot && nodeC.isLeaf)
        XCTAssertTrue(nodeA.linksAreConsistent())
        XCTAssertTrue(nodeB.linksAreConsistent())
        XCTAssertTrue(nodeC.linksAreConsistent())
    }

    func testNodeReplacement() {
        let nodeA = ParseNode(symbol: 23), nodeB = ParseNode(symbol: 29), nodeC = ParseNode(symbol: 29)
        XCTAssert(nodeA.isRoot && nodeA.isLeaf)
        XCTAssert(nodeB.isRoot && nodeB.isLeaf)
        XCTAssert(nodeC.isRoot && nodeC.isLeaf)
        
        let (oldPreviousOfB, ejectedNextFromA) = nodeB.follow(nodeA)
        let nodeD = ParseNode(symbol: 31)
        nodeD.follow(nodeB)
        XCTAssertNil(oldPreviousOfB)
        XCTAssertNil(ejectedNextFromA)
        XCTAssertTrue(nodeB.follows(nodeA))
        XCTAssertFalse(nodeC.follows(nodeA))
        XCTAssertTrue(nodeD.follows(nodeB))
        XCTAssertTrue(nodeD.follows(nodeA))
        XCTAssertFalse(nodeD.follows(nodeC))

        let (oldPreviousOfC, anotherEjectedNextFromA) = nodeC.follow(nodeA)
        XCTAssertNil(oldPreviousOfC)
        XCTAssertNotNil(anotherEjectedNextFromA)
        XCTAssert(anotherEjectedNextFromA === nodeB)
        XCTAssertFalse(nodeB.follows(nodeA))
        XCTAssertTrue(nodeC.follows(nodeA))
        XCTAssertTrue(nodeD.follows(nodeB))
        XCTAssertFalse(nodeD.follows(nodeA))
        XCTAssertFalse(nodeD.follows(nodeC))
    }

    func testBadLinks() {
        let nodeA = ParseNode(symbol: 4), nodeB = ParseNode(symbol: 6), nodeC = ParseNode(symbol: 8), nodeD = ParseNode(symbol: 9)
        nodeA.next[8] = nodeB
        nodeA.next[100] = nodeC
        nodeB.next[9] = nodeD
        nodeB.previous = nodeA
        nodeC.previous = nodeA
        nodeD.previous = nodeB
        XCTAssertTrue(nodeD.linksAreConsistent())
        XCTAssertFalse(nodeC.linksAreConsistent())
        XCTAssertFalse(nodeB.linksAreConsistent())
        XCTAssertFalse(nodeA.linksAreConsistent())
    }

    // Term-analyzers
    func testTreeTerminations() {
        let nodeA = ParseNode(symbol: 100), nodeB = ParseNode(symbol: 101), nodeC = ParseNode(symbol: 102), nodeD = ParseNode(symbol: 103)
        nodeB.follow(nodeA)
        nodeC.follow(nodeA)
        nodeD.follow(nodeC)
        XCTAssertFalse(nodeA.isLeaf)
        XCTAssertTrue(nodeB.isLeaf)
        XCTAssertFalse(nodeC.isLeaf)
        XCTAssertTrue(nodeD.isLeaf)
        XCTAssertTrue(nodeB.follows(nodeA))
        XCTAssertTrue(nodeC.follows(nodeA))
        XCTAssertTrue(nodeD.follows(nodeC))
        XCTAssertTrue(nodeD.follows(nodeA))

        // The nodes' "isTerminal" properties will be flipped in Gray's Code order.  This is the all-FALSE case block.
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0000
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeA.isTerminal = true
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0001
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeB.isTerminal = true
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0011
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeA.isTerminal = false
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0010
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        //XCTAssertEqual(nodeA.terminals(), [])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeC.isTerminal = true
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0110
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100, 102], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [[102]])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeA.isTerminal = true
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0111
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 102], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [[102]])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeB.isTerminal = false
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0101
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 102]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [[102]])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeA.isTerminal = false
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 0100
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertFalse(nodeC.treeIsProperlyTerminated())
        XCTAssertFalse(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100, 102]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [[102]])
        XCTAssertEqual(nodeD.terminals(), [])

        nodeD.isTerminal = true
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 1100
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100, 102], [100, 102, 103]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [[102], [102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeA.isTerminal = true
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 1101
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 102], [100, 102, 103]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [[102], [102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeB.isTerminal = true
        XCTAssertTrue(nodeA.treeIsProperlyTerminated())  // 1111
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 102], [100, 102, 103], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [[102], [102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeA.isTerminal = false
        XCTAssertTrue(nodeA.treeIsProperlyTerminated())  // 1110
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100, 102], [100, 102, 103], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [[102], [102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeC.isTerminal = false
        XCTAssertTrue(nodeA.treeIsProperlyTerminated())  // 1010
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100, 102, 103], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [[102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeA.isTerminal = true
        XCTAssertTrue(nodeA.treeIsProperlyTerminated())  // 1011
        XCTAssertTrue(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 102, 103], [100, 101]])
        XCTAssertEqual(nodeB.terminals(), [[101]])
        XCTAssertEqual(nodeC.terminals(), [[102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeB.isTerminal = false
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 1001
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100], [100, 102, 103]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [[102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])

        nodeA.isTerminal = false
        XCTAssertFalse(nodeA.treeIsProperlyTerminated())  // 1000
        XCTAssertFalse(nodeB.treeIsProperlyTerminated())
        XCTAssertTrue(nodeC.treeIsProperlyTerminated())
        XCTAssertTrue(nodeD.treeIsProperlyTerminated())
        XCTAssertEqual(nodeA.terminals(), [[100, 102, 103]])
        XCTAssertEqual(nodeB.terminals(), [])
        XCTAssertEqual(nodeC.terminals(), [[102, 103]])
        XCTAssertEqual(nodeD.terminals(), [[103]])
    }

    // Combining multiple terms
    func testMerging() {
        let nodeA = ParseNode(symbol: 2), nodeB = ParseNode(symbol: 3)
        XCTAssert(nodeA.isLeaf && nodeA.isRoot)
        XCTAssert(nodeB.isLeaf && nodeB.isRoot)

        let abandoned1 = nodeB.followWhileMergingParsingData(nodeA)
        XCTAssertTrue(abandoned1.isEmpty)
        XCTAssertTrue(nodeB.follows(nodeA))

        let abandoned2 = nodeB.followWhileMergingParsingData(nodeA)
        XCTAssertTrue(abandoned2.isEmpty)
        XCTAssertTrue(nodeB.follows(nodeA))

        let nodeC = ParseNode(symbol: 5)
        let abandoned3 = nodeC.followWhileMergingParsingData(nodeA)
        XCTAssertTrue(abandoned3.isEmpty)
        XCTAssertTrue(nodeC.follows(nodeA))
        XCTAssertTrue(nodeB.follows(nodeA))

        XCTAssertEqual(nodeA.terminals(), [])
        nodeB.isTerminal = true
        XCTAssertEqual(nodeA.terminals(), [[2, 3]])

        let nodeD = ParseNode(symbol: 3)
        XCTAssertFalse(nodeD.isTerminal)
        let abandoned4 = nodeD.followWhileMergingParsingData(nodeA)
        XCTAssertEqual(abandoned4.count, 1)
        XCTAssert(abandoned4[0] === nodeB)
        XCTAssertFalse(nodeB.follows(nodeA))
        XCTAssertTrue(nodeD.follows(nodeA))
        XCTAssertTrue(nodeC.follows(nodeA))
        XCTAssertTrue(nodeD.isTerminal)

        let nodeE = ParseNode(symbol: 7)
        nodeE.follow(nodeD)
        let abandoned5 = nodeB.followWhileMergingParsingData(nodeA)
        XCTAssertEqual(abandoned5.count, 1)
        XCTAssert(abandoned5[0] === nodeD)
        XCTAssertTrue(nodeD.isRoot)
        XCTAssertTrue(nodeD.isLeaf)
        XCTAssertTrue(nodeE.follows(nodeB))

        let nodeF = ParseNode(symbol: 7), nodeG = ParseNode(symbol: 11)
        nodeF.follow(nodeD)
        nodeG.follow(nodeF)
        nodeF.isTerminal = true
        let abandoned6 = nodeD.followWhileMergingParsingData(nodeA)
        XCTAssertEqual(abandoned6.count, 2)
        XCTAssert(abandoned6[0] === nodeB)
        XCTAssert(abandoned6[1] === nodeF)
        XCTAssertTrue(nodeE.isTerminal)
        XCTAssertTrue(nodeE.follows(nodeD))
        XCTAssertTrue(nodeG.follows(nodeE))
        XCTAssertTrue(nodeG.follows(nodeA))
    }

}

//
//  LineReader.swift
//  XNW
//
//  Created by Daryle Walker on 2/24/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


// MARK: Data Block Iteration

/// Iterate over fixed-size sections of a Data block.
struct DataBlockIterator: IteratorProtocol {

    /// The data to traverse.
    let data: Data
    /// The offset into the data to read the next block from.
    private(set) var blockOffset = 0
    /// The number of bytes remaining.  Kept so the last block is the right size if it's short.
    private(set) var bytesRemaining: Int
    /// The size of each block (except possibly the last).
    let blockSize: Int

    /// Initialize with the data to read over and the chunk size.
    init(data: Data, blockSize: Int) {
        precondition(blockSize > 0)

        self.data = data
        self.bytesRemaining = data.count
        self.blockSize = blockSize
    }

    mutating func next() -> Data? {
        guard bytesRemaining > 0 else { return nil }
        defer { blockOffset += blockSize ; bytesRemaining -= blockSize }

        return data.subdata(in: blockOffset..<(blockOffset + min(bytesRemaining, blockSize)))
    }

}

// MARK: - Data Line Iteration

/// Iterate over Internet text line ranges from a Data block.
struct DataInternetLineIterator: IteratorProtocol {

    // MARK: Helper Types

    /// Descriptor of the location of a line
    typealias LineLocation = (indices: Range<Data.Index>, terminatorLength: Int)

    // MARK: Sizing and Checking Constants

    /// The chunk size.  Based off the newish standard (Advanced Format) disk buffer size.
    static let chunkSize = 4 * 1024
    /// Carriage return.
    static let cr: UInt8 = 13
    /// Carriage return as data.
    static let crData = Data(repeating: cr, count: 1)
    /// Line feed.
    static let lf: UInt8 = 10
    /// Line feed as data.
    static let lfData = Data(repeating: lf, count: 1)
    /// CRLF line break.
    static let crlfData = crData + lfData
    /// CR-CRLF mistaken line break.
    static let crcrlfData = crData + crlfData

    // MARK: Properties

    /// The data to traverse.
    var data: Data {
        return blockIterator.data
    }
    /// The data buffer size (except possibly the last).  Always at least 3 (i.e. length of CR-CRLF).
    var blockSize: Int {
        return blockIterator.blockSize
    }

    // Iterate over segments of the data, to limit read-ahead.
    private var blockIterator: DataBlockIterator
    // The current data segment.
    private var currentBlock: Data?
    // The offset of the current segment from the start of the data.
    private var blockOffset = 0
    // Offset of the last line start from the start of the current data segment
    private var lineOffsetFromBlock = 0
    // Any pending lines formed when transitioning segments
    private var lineQueue = [LineLocation]()
    // The byte offset to search from for the next line.
    private var lineStartOffset: Int = 0

    // MARK: Initializers

    /// Initialize with the data to read over.
    init(data: Data, blockSize: Int = chunkSize) {
        blockIterator = DataBlockIterator(data: data, blockSize: max(blockSize, 4))
    }

    // MARK: Protocol Compliance

    mutating func next() -> LineLocation? {
        // Don't iterate until already-found lines are expended.
        guard lineQueue.isEmpty else { return lineQueue.removeFirst() }

        if currentBlock == nil {
            self.goToNextBlock()  // Never generates line-queue entries, so don't check
        }
        guard let block = currentBlock else { return nil }

        // Find a CR and/or LF to end the current line.
        let searchOffset = max(0, lineOffsetFromBlock)
        let nextCr = block.range(of: DataInternetLineIterator.crData, options: [], in: searchOffset..<block.count)
        let nextLf = block.range(of: DataInternetLineIterator.lfData, options: [], in: searchOffset..<block.count)

        // Build the location of found line, or punt to next block to continue finding.
        let lowerBound = blockOffset + lineOffsetFromBlock
        let upperBound: Data.Index
        var capLength = 0
        switch (nextCr, nextLf) {
        case (nil, nil):
            // Punt to the next block to find line terminators
            fallthrough
        case (_, nil) where block.count - nextCr!.upperBound == 1 && block.last! == DataInternetLineIterator.cr:
            // Punt to the next block because this could be the two CRs of CR-CRLF
            fallthrough
        case (_, nil) where nextCr!.upperBound == block.count:
            // Punt to the next block because this could be the first CR of a CRLF or CR-CRLF
            self.goToNextBlock()
            return self.next()
        case (let terminator, nil), (nil, let terminator):
            // End the line and prepare the next one
            lineOffsetFromBlock = terminator!.upperBound
            upperBound = blockOffset + lineOffsetFromBlock
            capLength = 1
        default:
            let terminator: Range<Data.Index>?
            switch nextLf!.lowerBound - nextCr!.lowerBound {
            case 2 where block[nextCr!.upperBound] == DataInternetLineIterator.cr:
                // Found a CR-CRLF
                capLength += 1
                fallthrough
            case 1:
                // Found a CRLF
                capLength += 1
                fallthrough
            case .min...0:
                // Found a LF
                terminator = nextLf
                capLength += 1
            default:
                // Found a CR
                terminator = nextCr
                capLength = 1
            }
            lineOffsetFromBlock = terminator!.upperBound
            upperBound = blockOffset + lineOffsetFromBlock
        }
        return (indices: lowerBound..<upperBound, terminatorLength: capLength)
    }

    // MARK: Helper Methods

    // Iterate to next block
    private mutating func goToNextBlock() {
        let newPotentialBlock = blockIterator.next()
        if let oldBlock = currentBlock {
            if let newBlock = newPotentialBlock {
                blockOffset += oldBlock.count
                lineOffsetFromBlock -= oldBlock.count

                // Check if a definitive line-break can be found along the block boundary
                if lineOffsetFromBlock < 0 {
                    let lowerBound = blockOffset + lineOffsetFromBlock
                    let oldBlockUpperBound = blockOffset
                    if Data(oldBlock.suffix(2)) == Data(repeating: DataInternetLineIterator.cr, count: 2) {
                        if Data(newBlock.prefix(1)) == DataInternetLineIterator.lfData {
                            // CR-CRLF, majority on old side
                            lineQueue.append((indices: lowerBound..<oldBlockUpperBound + 1, terminatorLength: 3))
                            lineOffsetFromBlock = 1
                        } else {
                            // No incoming LF to finish off a CR-CR; push 2 lines, starting with pending data and first CR
                            lineQueue.append((indices: lowerBound..<oldBlockUpperBound - 1, terminatorLength: 1))
                            if Data(newBlock.prefix(2)) == DataInternetLineIterator.crlfData {
                                // Second CR part of CR-CRLF that is majority on new side
                                lineQueue.append((indices: (oldBlockUpperBound - 1)..<oldBlockUpperBound + 2, terminatorLength: 3))
                                lineOffsetFromBlock = 2
                            } else {
                                // Second CR is stand-alone
                                lineQueue.append((indices: (oldBlockUpperBound - 1)..<oldBlockUpperBound, terminatorLength: 1))
                                lineOffsetFromBlock = 0
                            }
                        }
                    } else if Data(oldBlock.suffix(1)) == DataInternetLineIterator.crData {
                        if Data(newBlock.prefix(2)) == DataInternetLineIterator.crlfData {
                            // CR-CRLF, majority on new side
                            lineQueue.append((indices: lowerBound..<oldBlockUpperBound + 2, terminatorLength: 3))
                            lineOffsetFromBlock = 2
                        } else if Data(newBlock.prefix(1)) == DataInternetLineIterator.lfData {
                            // CRLF, split on both sides
                            lineQueue.append((indices: lowerBound..<oldBlockUpperBound + 1, terminatorLength: 2))
                            lineOffsetFromBlock = 1
                        } else {
                            // No incoming LF to finish off a CRLF; push a line
                            lineQueue.append((indices: lowerBound..<oldBlockUpperBound, terminatorLength: 1))
                            lineOffsetFromBlock = 0
                        }
                    }
                }
            } else {
                // No more data, close any pending lines, assuming everything is a single unterminated line
                var lowerBound = blockOffset + lineOffsetFromBlock
                var upperBound = blockOffset + oldBlock.count
                var capLength = 0
                if Data(oldBlock.suffix(2)) == Data(repeating: DataInternetLineIterator.cr, count: 2) {
                    // No incoming LF to finish off a CR-CR; push 2 lines, starting with pending data and first CR
                    upperBound -= 1  // Exclude second CR
                    capLength = 1
                    lineQueue.append((indices: lowerBound..<upperBound, terminatorLength: capLength))

                    // Prepare the second CR
                    lowerBound = upperBound
                    upperBound += 1  // Just the second CR
                } else if Data(oldBlock.suffix(1)) == DataInternetLineIterator.crData {
                    // No incoming LF to finish off CR
                    capLength = 1
                }
                if upperBound > lowerBound {
                    lineQueue.append((indices: lowerBound..<upperBound, terminatorLength: capLength))
                }
            }
        }
        currentBlock = newPotentialBlock
    }

}

// MARK: - Line Sequence (Iteration)

/// Breaks a data sample into lines of text
public struct LineReader: LazySequenceProtocol, IteratorProtocol {

    // MARK: Properties

    /// The data to traverse.
    public var data: Data {
        return dataIterator.data
    }
    /// The buffer size, since data is read in piecemeal.
    public var blockSize: Int {
        return dataIterator.blockSize
    }

    /// Whether the previously read line had a terminator.
    public private(set) var previousHadTerminator: Bool?

    // The construct that does most of the work.
    private var dataIterator: DataInternetLineIterator
    // The various string encodings to try....
    private static let encodings: [String.Encoding] = [.ascii, .utf8, .isoLatin1, .nextstep, .windowsCP1252, .macOSRoman]
    // ...But the API can't handle the String.Encoding -> UInt conversion correctly.
    private static let rawEncodings = encodings.map { $0.rawValue }

    // MARK: Initializers

    /**
        Initializes this reader with the given data.

        - Parameter data: The data to be parsed into lines.

        - Postcondition:
            - `self.data == data`
            - `self.blockSize == DataInternetLineIterator.chunkSize`
            - `self.previousHadTerminator == nil`
    */
    public init(data: Data) {
        dataIterator = DataInternetLineIterator(data: data)
    }

    // MARK: Protocol Compliance, IteratorProtocol

    public mutating func next() -> String? {
        guard let rawLine = dataIterator.next() else { return nil }

        let nonTerminatorRange = Range<Data.Index>(rawLine.indices.lowerBound ..< rawLine.indices.upperBound - rawLine.terminatorLength)
        let lineData = dataIterator.data.subdata(in: nonTerminatorRange)
        let lineString = LineReader.stringConverted(from: lineData)
        previousHadTerminator = rawLine.terminatorLength > 0
        return lineString
    }

    /// Converts a data block to a string with suggested potential encodings.
    static func stringConverted(from data: Data) -> String {
        var result: NSString?
        let encoding = NSString.stringEncoding(for: data, encodingOptions: [.allowLossyKey: false, .suggestedEncodingsKey: LineReader.rawEncodings, .useOnlySuggestedEncodingsKey: true], convertedString: &result, usedLossyConversion: nil)
        assert(encoding != 0)  // Shouldn't happen since Mac-Roman has valid characters for all 256 values.
        return result as! String
    }

}

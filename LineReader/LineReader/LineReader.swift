/*!
    @file
    @brief Line-reading class.
    @details A class that reads blocks of binary data with a given set of delimiters.  Each line is submitted to another object that subject to a custom protocol.

    @copyright Daryle Walker, 2016, all rights reserved.
    @CFBundleIdentifier io.github.ctmacuser.LineReader
*/

import Foundation


/// Process data blocks from a `LineReader` object.
@objc
public protocol LineReaderDelegate {

    /**
        Receive a line-delimited block of data.
     
        - parameter reader: The `LineReader` object sending this message.
        - parameter data: The data block representing the read line.  The deliminator byte sequence is not included.  (If the last read delimiter was incomplete, its data *will* be included here instead.)
        - parameter lineTerminator: The byte sequence that flagged the end of the data block.  It can be empty if this method was called during `flushDataCallingDelegate` and the trailing data had no (or an incomplete) delimiter.
     */
    func delineateDataFromReader(reader: LineReader, data: NSData, lineTerminator: NSData)

}

/// Read raw data in blocks separated by a given set of delimiters.
public class LineReader: NSObject {

    /// The delegate that will receive incoming data.  Calls to it are synchronous.
    public weak var delegate: LineReaderDelegate?
    /// The set of byte sequences that each can end a block of input.
    public var terminators: Set<NSData> {
        return Set(self.parseTree.followupSymbols.map { self.parseTree.followerUsing($0)! }.flatMap { $0.terminals }.map { NSData(bytes: $0.withUnsafeBufferPointer {$0.baseAddress}, length: $0.count * strideof($0.dynamicType.Element.self)) })
    }

    /// The parsing tree to match incoming bytes to any delimiters.  (The root node isn't used.)
    var parseTree = ParseNode<UInt8>(symbol: 0)

    /**
        Initializes a new line-block reader.

        - parameter lineTerminators: A set of data blocks where each block can end a round of input if encountered while streaming data.

        - postcondition: `self.terminators == lineTerminators`
     */
    public init(lineTerminators: Set<NSData>) {
        super.init()
        lineTerminators.forEach { $0.parseTree?.followWhileMergingParsingData(self.parseTree) }
        self.parseTree.isTerminal = true  // For passing the following assert,... even when otherwise termless.
        assert(self.parseTree.properlyTerminated)
    }

    //func lineateData(data: NSData)
    //func flushDataCallingDelegate(callDelegate: Bool)

}

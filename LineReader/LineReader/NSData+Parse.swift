/*!
    @file
    @brief Byte-parsing extension.
    @details An extension to NSData with a new property returning the parse tree to match the object's string of byte values.

    @copyright Daryle Walker, 2016, all rights reserved.
    @CFBundleIdentifier io.github.ctmacuser.LineReader
*/

import Foundation


// Generate parsing trees
extension NSData {

    /// A node set to parse data blocks matching this object's value.
    var parseTree: ParseNode<UInt8>? {
        get {
            guard self.length > 0 else {
                return nil
            }

            var readFirst = false
            var first: ParseNode<UInt8>?
            var latest: ParseNode<UInt8>?
            self.enumerateByteRangesUsingBlock { (bytes, byteRange, stop) in
                for byte in UnsafeBufferPointer(start: UnsafePointer<UInt8>(bytes), count: byteRange.length) {
                    if readFirst {
                        let newNode = ParseNode(symbol: byte)
                        newNode.follow(latest!)
                        latest = newNode
                    } else {
                        first = ParseNode(symbol: byte)
                        latest = first
                        readFirst = true
                    }
                }
            }
            latest?.isTerminal = true
            return first
        }
    }

}

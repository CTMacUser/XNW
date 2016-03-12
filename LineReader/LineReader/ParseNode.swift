/*!
    @file
    @brief Parsing-node class.
    @details A class that represents nodes of a directed tree graph of symbols to match while parsing, including when term is possibly reached.

    @copyright Daryle Walker, 2016, all rights reserved.
    @CFBundleIdentifier io.github.ctmacuser.LineReader
*/


/// Nodes, including root, of the parsing tree
class ParseNode<Symbol: Hashable> {

    /// The node representing the previous symbol to match from the stream.  When not NIL, must match the invariants of `next` in the opposite direction.
    weak var previous: ParseNode?
    /// The symbol value to match
    let symbol: Symbol
    /// Whether or not a symbol match at this point could mean a parsing match.
    var isTerminal: Bool
    /// Matches for later symbols in the stream. Invariant for each element _X_: `X.key == X.value.symbol` **AND** `X.value.previous == self`.
    var next: [Symbol: ParseNode]

    /**
        Initializes a new parsing node.

        Objects are supposed to be immutable, but all properties besides `self.symbol` are mutable since setup is a multi-step process. The other properties may change as parse nodes/branches/trees are merged together.

        - parameter symbol: The value to match from the stream.

        - postcondition:
            - `self.previous == nil`
            - `self.symbol == symbol`
            - `self.isTerminal == false`
            - `self.next.isEmpty == true`
     */
    init(symbol: Symbol) {
        self.symbol = symbol
        self.isTerminal = false
        self.next = [:]
    }

}

// Parse-termination flagging
extension ParseNode {

    /// Whether or not the receiver's parse branch stops tracking later symbols.
    var isLeaf: Bool {
        get {
            return self.next.isEmpty
        }
    }

    /// Whether or not the receiver is the start node of its parse branch.
    var isRoot: Bool {
        get {
            return self.previous == nil
        }
    }

    /// Checks whether or not all paths in the receiver's parse tree end with a terminal
    func treeIsProperlyTerminated() -> Bool {
        return self.isLeaf ? self.isTerminal : self.next.values.reduce(true, combine:{ return $0 && $1.treeIsProperlyTerminated() })
    }

}

// Chaining nodes for processing order
extension ParseNode {

    /// Verifies the connections between the receiver and its symbol-stream predecessor and successors.
    func linksAreConsistent() -> Bool {
        if let previous = self.previous {
            if previous.next[self.symbol] !== self {
                return false
            }
        }

        for (nextSymbol, nextNode) in self.next {
            if nextSymbol != nextNode.symbol || self !== nextNode.previous || !nextNode.linksAreConsistent() {
                return false
            }
        }

        return true
    }

    /**
        Check if the receiver follows the given node when parsing a stream.

        - parameter predecessor: The possible eariler node.

        - returns: Whether or not the receiver follows `predecessor`, directly or indirectly.
     */
    func follows(predecessor: ParseNode) -> Bool {
        if let previous = self.previous {
            return previous === predecessor || previous.follows(predecessor)
        } else {
            return false
        }
    }

    /**
        Disconnect the receiver from the node that immediately preceeds it in parsing the symbol-stream.

        - postcondition:
            - Let *X* be `self.previous` pre-run: if *X* is not NIL, then `X.next[self.symbol] == nil`.
            - `self.previous == nil`.

        - returns: *X*.
     */
    func unfollow() -> ParseNode? {
        if let previous = self.previous {
            let me = previous.next.removeValueForKey(self.symbol)
            me?.previous = nil
            assert(me === self)
            return previous
        }
        return nil
    }

    /**
        Connect the receiver as a follower to the given node, disconnecting the links in the way.

        - parameter predecessor: The node to be the (new) immediately-preceeding node while parsing a symbol-stream.

        - precondition:
            - `predecessor` and `self` must be distinct objects.
            - `predecessor` cannot already be a later node from the receiver while parsing a symbol-stream.

        - postcondition:
            - First, let *Next* be `predecessor.next[self.symbol]` and *Previous* be `self.previous`, both pre-run.
            - If *Previous* is not NIL and not `predecessor`: `Previous.next[self.symbol] == nil`.
            - If *Next* is not NIL and not `self`: `Next.previous == nil`.
            - `self.previous === predecessor`.
            - `predecessor.next[self.symbol] === self`.
     
        - returns: *Previous* and *Next* (in that order). Either may be NIL.
     */
    func follow(predecessor: ParseNode) -> (ParseNode?, ParseNode?) {
        assert(predecessor !== self)
        assert(!predecessor.follows(self))

        let ancestor = self.unfollow()
        self.previous = predecessor

        let supplanted = predecessor.next.updateValue(self, forKey: self.symbol)
        assert(self.symbol == (supplanted ?? self).symbol)
        // The following line is bad when `supplanted === self`.  However, that can't happen.  Any `self`/`supplanted` connection would require `ancestor` to be the same object as `predecessor`, but the `updateValue` call recreates the connection between `self` and `ancestor`/`predecessor` instead of displacing the old one, since that old connection was removed during `self.unfollow()`!
        supplanted?.previous = nil

        return (ancestor, supplanted)
    }

}

// Get and set match chains
extension ParseNode {

    /// Return the set of symbol sequences that can be matched by this parse tree.
    func terminals() -> [[Symbol]] {  // Can't make a Set of Array (since the latter is not Hashable)!
        var matchedSet = [[Symbol]]()
        let baseSymbol = [self.symbol]
        if self.isTerminal {
            matchedSet.append(baseSymbol)
        }
        matchedSet.appendContentsOf(self.next.values.flatMap { $0.terminals() }.map { baseSymbol + $0 })
        return matchedSet
    }

    /**
        Adds the receiver as a follower to the given node, but merging its parsing data with the data of the node it replaced (if any).

        - parameter predecessor: The node to be the (new) immediately-preceeding node while parsing a symbol-stream.

        - precondition: The same as `self.follow(predecessor)`.

        - postcondition:
            - First, start with the postconditions from `(Previous, Next) = self.follow(predecessor)`.
            - If *Next* is not NIL, `self.isTerminal` becomes itself OR'd with `Next.isTerminal`.
            - `Next.next.isEmpty` is TRUE when *Next* is distinct from `self`.
            - The sub-nodes of *Next* are in `self`, recursively added with this method (if needed).

        - returns: A collection of the disconnected nodes.  When *Next* is neither NIL nor `self`, the collection consists of *Next*, the sub-nodes of `self` that were displaced by sub-nodes of *Next*, and so on.  (At each recursive level, the sources of the kept and discarded nodes alternate between `self` and *Next*.)
     */
    func followWhileMergingParsingData(predecessor: ParseNode) -> [ParseNode] {
        var orphaned = [ParseNode]()
        let (_, supplanted) = self.follow(predecessor)
        if let mergable = supplanted {
            self.isTerminal = self.isTerminal || mergable.isTerminal
            orphaned.append(mergable)

            // Using mergable.next.values directly to transfer sub-nodes to self would involve self-modification of a lazy collection.  To avoid any issues there, first copy references to the sub-nodes to a new collection.  The recursive call from each sub-node returns an array too, so use 'flatMap' to avoid an array of arrays.
            orphaned.appendContentsOf([ParseNode](mergable.next.values).flatMap { return $0.followWhileMergingParsingData(self) })
        }
        return orphaned
    }

}

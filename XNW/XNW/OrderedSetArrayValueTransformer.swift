//
//  OrderedSetArrayValueTransformer.swift
//  XNW
//
//  Created by Daryle Walker on 2/15/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


/**
    A value transformer from a `NSOrderedSet` to `NSArray`.  Useful since Core Data uses `NSOrderedSet` for its ordered to-many collections, but `NSArrayController` only works with `NSArray` and `NSSet`.

    This class solves a problem I had, that's described on StackOverflow as ["Binding an Ordered Relationship with an NSArrayController"](http://stackoverflow.com/questions/15078679/binding-an-ordered-relationship-with-an-nsarraycontroller).  The links of the posted solution are both dead, but I found a copy of the [article](http://www.wannabegeek.com/?p=74) at a web-archive site.  (His GitHub page doesn't have the matching repository.)
 */
class OrderedSetArrayValueTransformer: ValueTransformer {

    /// The name of this type.  Could be used as a tag for registring this transformer.
    static let name = NSValueTransformerName(rawValue: String(describing: OrderedSetArrayValueTransformer.self))

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        return (value as? NSOrderedSet)?.array
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let array = value as? NSArray else { return nil }

        return NSOrderedSet(array: array as! [Any])
    }

}

//
//  RawHeaderField+CoreDataProperties.swift
//  XNW
//
//  Created by Daryle Walker on 2/10/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation
import CoreData


extension RawHeaderField {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RawHeaderField> {
        return NSFetchRequest<RawHeaderField>(entityName: "HeaderField");
    }

    @NSManaged public var body: String  // Originally generated as "String?"
    @NSManaged public var name: String  // Originally generated as "String?"
    @NSManaged public var message: RawMessage?

}

// This and the following lines were added.

extension RawHeaderField: InternetMessageHeaderMutableField {
    // There's a linker error unless this declaration is in the same file where its needed components are defined.
}

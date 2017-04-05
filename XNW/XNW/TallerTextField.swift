//
//  TallerTextField.swift
//  XNW
//
//  Created by Daryle Walker on 4/1/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa


/// A text field that acknowledges when it needs more height.
class TallerTextField: NSTextField {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    override var intrinsicContentSize: NSSize {
        guard let cell = self.cell, cell.wraps else { return super.intrinsicContentSize }

        validateEditing()
        return cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: frame.width, height: .greatestFiniteMagnitude))
    }

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        self.invalidateIntrinsicContentSize()

        if let rowView = superview?.superview as? NSTableRowView, let tableView = rowView.superview as? NSTableView {
            tableView.enumerateAvailableRowViews { currentRowView, currentRowIndex in
                if rowView === currentRowView {
                    tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: currentRowIndex))
                }
            }
        }
    }

}

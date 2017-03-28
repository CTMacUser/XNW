//
//  Defaults.swift
//  XNW
//
//  Created by Daryle Walker on 3/26/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation
import AppKit


/// Container for user-default keys and conversion functions
struct Defaults {

    // MARK: Types

    /// Keys for app-specific preferences
    enum KeyNames {
        static let listFont = "ListFont"
        static let textFont = "TextFont"
    }

    // MARK: Properties

    /// The default preferences for this app.
    static let appDefaults: [String: Any] = [
        KeyNames.listFont: Defaults.encode(from: NSFont.userFont(ofSize: 0)!),
        KeyNames.textFont: Defaults.encode(from: NSFont.userFixedPitchFont(ofSize: 0)!),
    ]

    // MARK: Conversions

    /// Convert stored font data back into a font object.
    static func decodeFont(from data: Data) -> NSFont {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as! NSFont
    }

    /// Convert a font object to data that can be stored in a default.
    static func encode(from font: NSFont) -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: font)
    }

}

// MARK: - Access Methods for New Types

extension UserDefaults {

    /// Returns the font object associated with the specified key.
    func font(forKey defaultName: String) -> NSFont? {
        guard let fontData = self.data(forKey: defaultName) else { return nil }

        return Defaults.decodeFont(from: fontData)
    }

    /// Sets the value of the specified default key to the specified font.
    func set(_ font: NSFont?, forKey defaultName: String) {
        let fontData: Data?
        if let font = font {
            fontData = Defaults.encode(from: font)
        } else {
            fontData = nil
        }
        self.set(fontData, forKey: defaultName)
    }

}

// MARK: Access Properties for Custom Defaults

extension UserDefaults {

    /// Font for list views.
    var listFont: NSFont {
        get {
            return self.font(forKey: Defaults.KeyNames.listFont)!
        }
        set {
            self.set(newValue, forKey: Defaults.KeyNames.listFont)
        }
    }

    /// Font for text-block views.
    var textFont: NSFont {
        get {
            return self.font(forKey: Defaults.KeyNames.textFont)!
        }
        set {
            self.set(newValue, forKey: Defaults.KeyNames.textFont)
        }
    }

}

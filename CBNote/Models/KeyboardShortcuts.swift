//
//  KeyboardShortcuts.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/14.
//

import Foundation

extension Notification.Name {
    static let customKeyboardShortcutPerformed = Notification.Name("customKeyboardShortcutPerformed")
}

enum CustomKeyboardShortcut: String {
    case openSettings
    case reloadFiles
    case pasteFromClipboard
    case addNewNote
}


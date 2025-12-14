//
//  CBNoteApp.swift
//  CBNote
//
//  Created by Cizzuk on 2025/11/29.
//

import SwiftUI

@main
struct CBNoteApp: App {
    init() {
        // Initialize Watch Connectivity Manager
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button {
                    NotificationCenter.default.post(
                        name: .customKeyboardShortcutPerformed,
                        object: CustomKeyboardShortcut.openSettings
                    )
                } label: {
                    Label("Settings...", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            
            CommandGroup(before: .undoRedo) {
                Button {
                    NotificationCenter.default.post(
                        name: .customKeyboardShortcutPerformed,
                        object: CustomKeyboardShortcut.reloadFiles
                    )
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("R", modifiers: [.command])
                
            }
            
            CommandGroup(replacing: .newItem) {
                Button {
                    NotificationCenter.default.post(
                        name: .customKeyboardShortcutPerformed,
                        object: CustomKeyboardShortcut.addNewNote
                    )
                } label: {
                    Label("Add New Note", systemImage: "plus")
                }
                .keyboardShortcut("N", modifiers: [.command])

                Button {
                    NotificationCenter.default.post(
                        name: .customKeyboardShortcutPerformed,
                        object: CustomKeyboardShortcut.pasteFromClipboard
                    )
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }
                .keyboardShortcut("V", modifiers: [.command, .shift])
            }
        }
    }
}

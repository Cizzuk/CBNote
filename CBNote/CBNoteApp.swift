//
//  CBNoteApp.swift
//  CBNote
//
//  Created by Cizzuk on 2025/11/29.
//

import SwiftUI
import UIKit

@main
struct CBNoteApp: App {
    init() {
        // Initialize Watch Connectivity Manager
        _ = WatchConnectivityManager.shared
    }
    
    static func handleURLScheme(_ url: URL) {
        if url.host == "magicaction" {
            switch url.path {
            case "/home":
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            case "/kill":
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                exit(0)
            default:
                break
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    CBNoteApp.handleURLScheme(url)
                }
            #if targetEnvironment(macCatalyst)
            .onAppear {
                (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .titlebar?
                    .titleVisibility = .hidden
            }
            #endif
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

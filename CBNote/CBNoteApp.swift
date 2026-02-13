//
//  CBNoteApp.swift
//  CBNote
//
//  Created by Cizzuk on 2025/11/29.
//

import SwiftUI
import UIKit

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Scene Delegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let action: OpenAppOption?
        switch shortcutItem.type {
        case "net.cizzuk.cbnote.HomeShortcut.LaunchCamera":
            action = .launchCamera
        case "net.cizzuk.cbnote.HomeShortcut.PasteFromClipboard":
            action = .pasteFromClipboard
        case "net.cizzuk.cbnote.HomeShortcut.AddNewNote":
            action = .addNewNote
        default:
            action = nil
        }
        
        if let action {
            NotificationCenter.default.post(name: .openAppIntentPerformed, object: action)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
}

// MARK: - App Entry Point
@main
struct CBNoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize Watch Connectivity Manager
        _ = WatchConnectivityManager.shared
        // Update Capture Context
        CaptureContext.syncContextSettings()
    }
    
    // Only to be used by user actions
    static func backToHomeScreen() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    }
    
    static func exitApp() {
        backToHomeScreen()
        exit(0)
    }
    
    var body: some Scene {
        // MARK: - Window Group
        WindowGroup {
            MainView()
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
                    Label("Add New Note", systemImage: "square.and.pencil")
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

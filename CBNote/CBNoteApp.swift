//
//  CBNoteApp.swift
//  CBNote
//
//  Created by Cizzuk on 2025/11/29.
//

import SwiftUI
import SwiftData

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
    }
}

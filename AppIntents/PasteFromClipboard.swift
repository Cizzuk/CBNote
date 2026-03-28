//
//  PasteFromClipboard.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppPasteFromClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Paste from Clipboard"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .openAppIntentPerformed, object: OpenAppOption.pasteFromClipboard)
        return .result()
    }
}

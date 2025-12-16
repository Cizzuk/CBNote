//
//  PasteFromClipboard.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppPasteFromClipboardControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppPasteFromClipboardControl"
    static let title: LocalizedStringResource = "Paste from Clipboard"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppPasteFromClipboardControl.kind) {
            ControlWidgetButton(action: OpenAppPasteFromClipboardIntent()) {
                Label(OpenAppPasteFromClipboardControl.title, systemImage: "document.on.clipboard")
            }
        }
        .displayName(OpenAppPasteFromClipboardControl.title)
    }
}

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

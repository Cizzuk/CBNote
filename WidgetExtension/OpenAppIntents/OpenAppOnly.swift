//
//  OpenAppOnly.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppOpenAppOnlyControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppOpenAppOnlyControl"
    static let title: LocalizedStringResource = "Open CBNote"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppOpenAppOnlyControl.kind) {
            ControlWidgetButton(action: OpenAppOpenAppOnlyIntent()) {
                Label(OpenAppOpenAppOnlyControl.title, systemImage: "arrow.up.forward.app.fill")
            }
        }
        .displayName(OpenAppOpenAppOnlyControl.title)
    }
}

struct OpenAppOpenAppOnlyIntent: AppIntent {
    static let title: LocalizedStringResource = "Open CBNote"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .openAppIntentPerformed, object: OpenAppOption.openAppOnly)
        return .result()
    }
}

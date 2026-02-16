//
//  StartRecording.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2026/02/16.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppStartRecordingControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppStartRecordingControl"
    static let title: LocalizedStringResource = "Start Recording on CBNote"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppStartRecordingControl.kind) {
            ControlWidgetButton(action: OpenAppStartRecordingIntent()) {
                Label(OpenAppStartRecordingControl.title, systemImage: "waveform.badge.microphone")
            }
        }
        .displayName(OpenAppStartRecordingControl.title)
    }
}

struct OpenAppStartRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Recording"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .openAppIntentPerformed, object: OpenAppOption.startRecording)
        return .result()
    }
}

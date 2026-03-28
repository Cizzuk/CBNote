//
//  StartRecording.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2026/02/16.
//

import WidgetKit
import AppIntents
import SwiftUI

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

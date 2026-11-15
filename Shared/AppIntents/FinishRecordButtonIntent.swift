//
//  FinishRecordButtonIntent.swift
//  CBNote
//
//  Created by Cizzuk on 2026/09/29.
//

import AppIntents

struct FinishRecordButtonIntent: AppIntent {
    static let title: LocalizedStringResource = "Finish Record"
    static var isDiscoverable = false
    static var supportedModes: IntentModes = .foreground(.dynamic)

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .shouldFinishRecording, object: nil)
        return .result()
    }
}

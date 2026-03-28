//
//  SetCameraControlAction.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/28.
//

import AppIntents

struct SetCameraControlAction: AppIntent {
    static let title: LocalizedStringResource = "Set Camera Control Action"
    static let description: LocalizedStringResource = "Sets an action when launched from Camera Control."
    
    static let openAppWhenRun = false
    static let isDiscoverable = TrueDevice.isCamControlAvailable
    
    @Parameter(title: "Action", default: .launchCamera)
    var action: OpenAppOption
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set Camera Control Action to \(\.$action)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.cameraControlAction = action
        return .result()
    }
}

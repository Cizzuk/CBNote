//
//  SetURLForOpenURLAction.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/28.
//

import AppIntents

struct SetURLForOpenURLAction: AppIntent {
    static let title: LocalizedStringResource = "Set URL for Open URL Action"
    static let description: LocalizedStringResource = "Sets a URL to be used in the Open URL action."
    
    static let openAppWhenRun = false
    static let isDiscoverable = TrueDevice.isCamControlAvailable
    
    @Parameter(title: "URL")
    var url: URL
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set URL for Open URL Action to \(\.$url)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(url.absoluteString, forKey: "cameraControlActionOpenURL")
        return .result()
    }
}

//
//  CaptureContext.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/05.
//

import Foundation

nonisolated
struct CaptureContext: Codable {
    enum LaunchAction: String, Codable, CaseIterable, Identifiable {
        case launchCamera = "Launch Camera"
        case openApp = "Open App"
        case doNothing = "Do Nothing"
        
        var id: String { rawValue }
        var localizedName: LocalizedStringResource {
            switch self {
            case .launchCamera:
                return "Launch Camera"
            case .openApp:
                return "Open App"
            case .doNothing:
                return "Do Nothing"
            }
        }
    }
    
    var launchAction: LaunchAction = .launchCamera
}

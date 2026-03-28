//
//  CaptureContext.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/05.
//

import AppIntents

nonisolated
struct CaptureContext: Codable {
    enum LaunchAction: String, Codable, CaseIterable, Identifiable {
        case runCameraControlAction
        case launchCamera
        case openAppOnly
        
        var id: String { rawValue }
    }
    
    var launchAction: LaunchAction = .runCameraControlAction
}

// MARK: - Context Management

#if !EXTENSION
extension CaptureContext {
    static func syncContextSettings() {
        let launchAction = getLaunchAction()
        
        Task {
            let context = CaptureContext(launchAction: launchAction)
            do {
                try await CaptureIntent.updateAppContext(context)
            } catch {
                print("Failed to update app context: \(error)")
            }
        }
    }
    
    private static func getLaunchAction() -> LaunchAction {
        let cameraControlAction = UserSettings.shared.cameraControlAction
        
        let launchAction: LaunchAction
        switch cameraControlAction {
        case .launchCamera:
            launchAction = .launchCamera
        case .openAppOnly:
            launchAction = .openAppOnly
        default:
            launchAction = .runCameraControlAction
        }
        
        return launchAction
    }
}
#endif

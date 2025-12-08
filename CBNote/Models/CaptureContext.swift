//
//  CaptureContext.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/05.
//

import Foundation
import SwiftUI

nonisolated
struct CaptureContext: Codable {
    enum LaunchAction: String, Codable, CaseIterable, Identifiable {
        case launchCamera = "Launch Camera"
        case doNothing = "Do Nothing"
        
        var id: String { rawValue }
        var localizedName: String.LocalizationValue {
            switch self {
            case .launchCamera:
                return "Launch Camera"
            case .doNothing:
                return "Do Nothing"
            }
        }
    }
    
    var launchAction: LaunchAction = .launchCamera
}

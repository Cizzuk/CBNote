//
//  Constants.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/07.
//

import AVFoundation
import Foundation

let GroupUserDefaults = UserDefaults(suiteName: "group.net.cizzuk.cbnote")!

extension Notification.Name {
    static let assistantDidActivate = Notification.Name("assistantDidActivate")
    static let shouldFinishRecording = Notification.Name("shouldFinishRecording")
}

extension AVCaptureDevice.FlashMode {
    var accessibilityValue: LocalizedStringResource {
        switch self {
        case .off:  return "Flash Off"
        case .on:   return "Flash On"
        case .auto: return "Flash Auto"
        @unknown default:
            return "Unknown Flash Mode"
        }
    }
    
    var systemImage: String {
        switch self {
        case .off:  return "bolt.slash"
        case .on:   return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        @unknown default:
            return "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}

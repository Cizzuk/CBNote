//
//  TrueDevice.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/14.
//

import UIKit

enum DocumentDir: String, CaseIterable {
    case onDevice
    case iCloud
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .onDevice:
            switch TrueDevice.userInterfaceIdiom {
            case .phone:
                return "On My iPhone"
            case .pad:
                return "On My iPad"
            case .mac:
                return "On My Mac"
            case .vision:
                return "On My Apple Vision"
            case .tv:
                return "On My Apple TV"
            case .carPlay:
                return "On My CarPlay"
            default:
                return "On My Device"
            }
        case .iCloud:
            return "iCloud Drive"
        }
    }
    
    var systemImage: String {
        switch self {
        case .onDevice:
            switch TrueDevice.userInterfaceIdiom {
            case .phone:
                return "iphone"
            case .pad:
                return "ipad"
            case .mac:
                return "internaldrive"
            case .vision:
                return "vision.pro"
            case .tv:
                return "appletv"
            default:
                return "internaldrive"
            }
        case .iCloud:
            return "icloud"
        }
    }
    
    var directory: URL? {
        switch self {
        case .onDevice:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .iCloud:
            return iCloudSupport.directoryURL
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .onDevice:
            return true
        case .iCloud:
            return iCloudSupport.isAvailable
        }
    }
    
    static var availableDirs: [DocumentDir] {
        return DocumentDir.allCases.filter { $0.isAvailable }
    }
    
    static var defaultDir: DocumentDir {
        if DocumentDir.iCloud.isAvailable {
            return .iCloud
        } else {
            return .onDevice
        }
    }

    // For UserDefaults
    var pinnedKey: String {
        switch self {
        case .onDevice:
            return "pinnedFiles_OnDevice"
        case .iCloud:
            return "pinnedFiles_iCloud"
        }
    }
}

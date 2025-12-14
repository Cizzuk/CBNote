//
//  AppStateSupport.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/14.
//

import Foundation
import UIKit

enum DocumentDir: String, CaseIterable {
    case onDevice
    case iCloud
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .onDevice:
            #if targetEnvironment(macCatalyst)
            return "On My Mac"
            #endif
            let device = UIDevice.current.userInterfaceIdiom
            switch device {
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
            return "iCloud"
        }
    }
    
    var systemImage: String {
        switch self {
        case .onDevice:
            #if targetEnvironment(macCatalyst)
            return "internaldrive"
            #endif
            let device = UIDevice.current.userInterfaceIdiom
            switch device {
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
            if self.isAvailable,
               let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
                return url.appendingPathComponent("Documents")
            } else {
                print("iCloud container not available")
                return nil
            }
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .onDevice:
            return true
        case .iCloud:
            return FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
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

enum SortKey: String, CaseIterable {
    case name // Default
    case date // Modification Date
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .name:
            return "Name"
        case .date:
            return "Date"
        }
    }
}

enum SortDirection: String {
    case descending // Default
    case ascending
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .descending:
            return "Descending"
        case .ascending:
            return "Ascending"
        }
    }
}

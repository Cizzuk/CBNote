//
//  OpenAppSupport.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/08.
//

import UIKit

extension Notification.Name {
    static let openAppIntentPerformed = Notification.Name("openAppIntentPerformed")
}

enum OpenAppOption: String, CaseIterable, Identifiable, Codable {
    case launchCamera = "Launch Camera"
    case pasteFromClipboard = "Paste from Clipboard"
    case addNewNote = "Add New Note"
    case startRecording = "Start Recording"
    case openAppOnly = "Open App Only"
    case openURL = "Open URL"

    var id: String { rawValue }
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .launchCamera:
            return "Launch Camera"
        case .pasteFromClipboard:
            return "Paste from Clipboard"
        case .addNewNote:
            return "Add New Note"
        case .startRecording:
            return "Start Recording"
        case .openAppOnly:
            return "Open App Only"
        case .openURL:
            return "Open URL"
        }
    }
    
    var shouldOpenDummyCamera: Bool {
        switch self {
        case .launchCamera, .openURL:
            return false
        case .pasteFromClipboard, .addNewNote, .startRecording, .openAppOnly:
            return true
        }
    }
}

extension OpenAppOption {
    static func urlToOption(_ url: URL) -> OpenAppOption? {
        // Get App URL Schemes
        let appURLSchemes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
        let urlSchemes = appURLSchemes?.compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 } ?? []
        
        // Check URL Scheme
        guard let scheme = url.scheme,
              urlSchemes.contains(scheme)
        else { return nil }
        
        // Parse URL
        switch url.host {
        case "open":
            switch url.pathComponents.dropFirst().first {
            case "camera":
                return .launchCamera
            case "paste":
                return .pasteFromClipboard
            case "newnote":
                return .addNewNote
            case "record":
                return .startRecording
            default:
                break
            }
        default:
            break
        }
        
        return .openAppOnly
    }
}

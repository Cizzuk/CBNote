//
//  OpenAppSupport.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/08.
//

import AppIntents
import UIKit

extension Notification.Name {
    static let openAppIntentPerformed = Notification.Name("openAppIntentPerformed")
}

enum OpenAppOption: String, CaseIterable, Identifiable, Codable, AppEnum {
    case launchCamera = "Launch Camera"
    case pasteFromClipboard = "Paste from Clipboard"
    case addNewNote = "Add New Note"
    case startRecording = "Start Recording"
    case openAppOnly = "Open App Only"
    case openURL = "Open URL"

    var id: String { rawValue }
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Open App Option")
    }
    
    static var caseDisplayRepresentations: [OpenAppOption : DisplayRepresentation] = [
        .launchCamera: "Launch Camera",
        .pasteFromClipboard: "Paste from Clipboard",
        .addNewNote: "Add New Note",
        .startRecording: "Start Recording",
        .openAppOnly: "Open App Only",
        .openURL: "Open URL"
    ]
    
    var displayName: LocalizedStringResource {
        return Self.caseDisplayRepresentations[self]?.title ?? ""
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

//
//  OpenAppOption.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/08.
//

import AppIntents

extension Notification.Name {
    static let openAppIntentPerformed = Notification.Name("openAppIntentPerformed")
}

enum OpenAppOption: String, CaseIterable, Identifiable, Codable, AppEnum {
    case openURL = "Open URL"
    case launchCamera = "Launch Camera"
    case pasteFromClipboard = "Paste from Clipboard"
    case addNewNote = "Add New Note"
    case startRecording = "Start Recording"
    case openAppOnly = "Open App Only"

    var id: String { rawValue }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Open App Option")
    }

    static var caseDisplayRepresentations: [OpenAppOption: DisplayRepresentation] = [
        .openURL: "Open URL",
        .launchCamera: "Launch Camera",
        .pasteFromClipboard: "Paste from Clipboard",
        .addNewNote: "Add New Note",
        .startRecording: "Start Recording",
        .openAppOnly: "Open App Only",
    ]

    var displayName: LocalizedStringResource {
        return Self.caseDisplayRepresentations[self]?.title ?? ""
    }

    var shouldOpenDummyCamera: Bool {
        switch self {
        case .openURL, .launchCamera:
            return false
        case .pasteFromClipboard, .addNewNote, .startRecording, .openAppOnly:
            return true
        }
    }
}

extension OpenAppOption {
    static func urlToOption(_ urlString: String) -> OpenAppOption? {
        if let url = URL(string: urlString) {
            return urlToOption(url)
        }
        return nil
    }

    static func urlToOption(_ url: URL) -> OpenAppOption? {
        // Check URL Scheme
        guard let scheme = url.scheme,
            AppURLSchemes.contains(scheme.lowercased())
        else { return nil }

        // Parse URL
        switch url.host?.lowercased() {
        case "open":
            switch url.pathComponents.dropFirst().first?.lowercased() {
            case "camera":
                return .launchCamera
            case "paste":
                return .pasteFromClipboard
            case "newnote":
                return .addNewNote
            case "record":
                return .startRecording
            case "app":
                return .openAppOnly
            default:
                break
            }
        default:
            break
        }

        return .openAppOnly
    }

    // Camera Control Action should be set to this URL using openURL
    var autoSetURL: String? {
        switch self {
        case .launchCamera:
            return nil
        case .pasteFromClipboard:
            return "cbnote://open/paste"
        case .addNewNote:
            return "cbnote://open/newnote"
        case .startRecording:
            return "cbnote://open/record"
        case .openAppOnly:
            return "cbnote://open/app"
        case .openURL:
            return nil
        }
    }
}

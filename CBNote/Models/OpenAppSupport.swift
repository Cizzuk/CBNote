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
    case openAppOnly = "Open App Only"

    var id: String { rawValue }
    var localizedName: LocalizedStringResource {
        switch self {
        case .launchCamera:
            return "Launch Camera"
        case .pasteFromClipboard:
            return "Paste from Clipboard"
        case .addNewNote:
            return "Add New Note"
        case .openAppOnly:
            return "Open App Only"
        }
    }
}

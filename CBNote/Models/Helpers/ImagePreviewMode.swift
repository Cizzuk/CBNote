//
//  ImagePreviewMode.swift
//  CBNote
//
//  Created by Cizzuk on 2026/06/24.
//

import Foundation

enum ImagePreviewMode: String, CaseIterable, Identifiable {
    case off, small, large
    
    static var `default`: ImagePreviewMode = .large
    var id: String { self.rawValue }
    
    var displayName: LocalizedStringResource {
        switch self {
        case .off:
            return "Off"
        case .small:
            return "Small"
        case .large:
            return "Large"
        }
    }
}

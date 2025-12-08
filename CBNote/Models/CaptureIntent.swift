//
//  File.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import Foundation
import AppIntents
import LockedCameraCapture

extension Notification.Name {
    static let cameraControlDidActivate = Notification.Name("cameraControlDidActivate")
}

struct CaptureIntent: CameraCaptureIntent {
    typealias AppContext = CaptureContext
    static let title: LocalizedStringResource = "CaptureIntent"
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .cameraControlDidActivate, object: nil)
        return .result()
    }
}

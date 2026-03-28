//
//  OpenAppOnly.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppOpenAppOnlyIntent: AppIntent {
    static let title: LocalizedStringResource = "Open CBNote"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .openAppIntentPerformed, object: OpenAppOption.openAppOnly)
        return .result()
    }
}

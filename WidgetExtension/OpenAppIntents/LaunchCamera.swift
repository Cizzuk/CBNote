//
//  LaunchCamera.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppLaunchCameraControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppLaunchCameraControl"
    static let title: LocalizedStringResource = "Launch Camera on CBNote"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppLaunchCameraControl.kind) {
            ControlWidgetButton(action: OpenAppLaunchCameraIntent()) {
                Label(OpenAppLaunchCameraControl.title, systemImage: "camera.on.rectangle.fill")
            }
        }
        .displayName(OpenAppLaunchCameraControl.title)
    }
}

struct OpenAppLaunchCameraIntent: AppIntent {
    static let title: LocalizedStringResource = "Launch Camera on CBNote"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .openAppIntentPerformed, object: OpenAppOption.launchCamera)
        return .result()
    }
}

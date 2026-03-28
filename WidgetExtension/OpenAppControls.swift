//
//  OpenAppControls.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/28.
//

import WidgetKit
import AppIntents
import SwiftUI

struct OpenAppLaunchCameraControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppLaunchCameraControl"
    static let title: LocalizedStringResource = "Launch CBNote Camera"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppLaunchCameraControl.kind) {
            ControlWidgetButton(action: OpenAppLaunchCameraIntent()) {
                Label(OpenAppLaunchCameraControl.title, systemImage: "camera.on.rectangle.fill")
            }
        }
        .displayName(OpenAppLaunchCameraControl.title)
    }
}

struct OpenAppPasteFromClipboardControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppPasteFromClipboardControl"
    static let title: LocalizedStringResource = "Paste from Clipboard"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppPasteFromClipboardControl.kind) {
            ControlWidgetButton(action: OpenAppPasteFromClipboardIntent()) {
                Label(OpenAppPasteFromClipboardControl.title, systemImage: "document.on.clipboard")
            }
        }
        .displayName(OpenAppPasteFromClipboardControl.title)
    }
}

struct OpenAppAddNewNoteControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppAddNewNoteControl"
    static let title: LocalizedStringResource = "Add New Note"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppAddNewNoteControl.kind) {
            ControlWidgetButton(action: OpenAppAddNewNoteIntent()) {
                Label(OpenAppAddNewNoteControl.title, systemImage: "square.and.pencil")
            }
        }
        .displayName(OpenAppAddNewNoteControl.title)
    }
}

struct OpenAppStartRecordingControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppStartRecordingControl"
    static let title: LocalizedStringResource = "Start Recording"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppStartRecordingControl.kind) {
            ControlWidgetButton(action: OpenAppStartRecordingIntent()) {
                Label(OpenAppStartRecordingControl.title, systemImage: "waveform.badge.microphone")
            }
        }
        .displayName(OpenAppStartRecordingControl.title)
    }
}

struct OpenAppOpenAppOnlyControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppOpenAppOnlyControl"
    static let title: LocalizedStringResource = "Open CBNote"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: OpenAppOpenAppOnlyControl.kind) {
            ControlWidgetButton(action: OpenAppOpenAppOnlyIntent()) {
                Label(OpenAppOpenAppOnlyControl.title, image: "cbnote")
            }
        }
        .displayName(OpenAppOpenAppOnlyControl.title)
    }
}

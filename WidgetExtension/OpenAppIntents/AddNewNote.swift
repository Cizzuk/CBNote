//
//  AddNewNote.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import AppIntents
import SwiftUI

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

struct OpenAppAddNewNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Add New Note"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .openAppIntentPerformed, object: OpenAppOption.addNewNote)
        return .result()
    }
}

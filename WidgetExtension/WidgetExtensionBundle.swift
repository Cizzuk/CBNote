//
//  WidgetExtensionBundle.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2025/12/05.
//

import WidgetKit
import SwiftUI

@main
struct WidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        #if !targetEnvironment(macCatalyst)
        OpenAppLaunchCameraControl()
        #endif
        OpenAppPasteFromClipboardControl()
        OpenAppAddNewNoteControl()
        OpenAppOpenAppOnlyControl()
    }
}

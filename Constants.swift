//
//  Constants.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/07.
//

import Foundation

let GroupUserDefaults = UserDefaults(suiteName: "group.net.cizzuk.cbnote")!

enum CFNotificationFlags {
    static let shouldFinishRecording = "CFNotification.shouldFinishRecording"
}

extension CFNotificationName {
    static let shouldFinishRecording = CFNotificationName("net.cizzuk.cbnote.CFNotification.shouldFinishRecording" as CFString)
}

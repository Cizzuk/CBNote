//
//  RecorderActivity.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/03.
//

import ActivityKit
import Foundation

#if targetEnvironment(macCatalyst)

class RecorderActivityManager {
    static func isActive() -> Bool {
        return false
    }
    
    static func start(endDate: Date? = nil) {
        print("Activities are not supported on macOS. Cannot start recorder activity.")
    }
    
    static func endAll() {
        print("Activities are not supported on macOS. No recorder activities to end.")
    }
}

#else

nonisolated struct RecorderActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable { }
}

class RecorderActivityManager {
    static func isActive() -> Bool {
        return !Activity<RecorderActivityAttributes>.activities.isEmpty
    }
    
    static func start(endDate: Date? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Activities are not enabled. Cannot start recorder activity.")
            return
        }
        endAll()
        
        let attributes = RecorderActivityAttributes()
        
        let contentState = RecorderActivityAttributes.ContentState()
        
        let content = ActivityContent(
            state: contentState,
            staleDate: endDate
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start recorder activity: \(error)")
        }
    }
    
    static func endAll() {
        let activities = Activity<RecorderActivityAttributes>.activities
        
        let contentState = RecorderActivityAttributes.ContentState()
        
        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )
        
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached(priority: .userInitiated) {
            for activity in activities {
                await activity.end(content, dismissalPolicy: .immediate)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}

#endif

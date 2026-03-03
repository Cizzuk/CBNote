//
//  RecorderActivity.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/03.
//

import ActivityKit
import Foundation

struct RecorderActivityAttributes: ActivityAttributes {
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
            print("Started recorder activity: \(activity)")
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
        
        for activity in activities {
            Task {
                await activity.end(
                    content,
                    dismissalPolicy: .immediate
                )
            }
            print("Ended recorder activity: \(activity)")
        }
    }
}

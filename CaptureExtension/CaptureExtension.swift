//
//  CaptureExtension.swift
//  CaptureExtension
//
//  Created by Cizzuk on 2025/11/30.
//

import AppIntents
import ExtensionKit
import LockedCameraCapture
import SwiftUI
import WidgetKit

@main
struct CaptureExtension: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            ExtensionContentView(session: session)
        }
    }
}

struct ExtensionContentView: View {
    let session: LockedCameraCaptureSession
    @State private var launchAction: CaptureContext.LaunchAction?
    
    var body: some View {
        ZStack {
            if let action = launchAction {
                switch action {
                case .launchCamera:
                    CameraView(isLockedMode: true) { data in
                        saveToSession(session, data: data)
                    }
                case .openApp:
                    Color.black
                        .ignoresSafeArea()
                        .task {
                            let activity = NSUserActivity(activityType: "net.cizzuk.cbnote.CaptureExtension")
                            try? await session.openApplication(for: activity)
                            exit(0)
                        }
                case .doNothing:
                    Color.black
                        .ignoresSafeArea()
                        .onAppear {
                            exit(0)
                        }
                }
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .task {
            do {
                if let context = try await CaptureIntent.appContext {
                    launchAction = context.launchAction
                } else {
                    launchAction = .launchCamera
                }
            } catch {
                launchAction = .openApp
            }
        }
    }
    
    private func saveToSession(_ session: LockedCameraCaptureSession, data: Data) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(timestamp).jpeg"
        let url = session.sessionContentURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: url)
        } catch {
            print("Error saving to session: \(error)")
        }
    }
}

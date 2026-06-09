//
//  CameraView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import AVKit
import SwiftUI
import UIKit

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var camera = CameraService()
    
    var isLockedMode: Bool = false
    var remainAfterCapture: Bool = false
    var onSave: (Data) -> Void
    
    @State private var alertMessage: LocalizedStringResource? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if camera.cameraPermission == .authorized {
                    CameraPreview(session: camera.session) { point in
                        camera.focus(at: point)
                    }
                    .ignoresSafeArea()
                    .opacity(camera.shouldFlashScreen ? 0 : 1)
                    .onCameraCaptureEvent(defaultSoundDisabled: true) { event in
                        if event.phase == .began {
                            camera.takePhoto()
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    
                    // Display alert message if it exists
                    if let message = alertMessage {
                        HStack {
                            Spacer()
                            Text(message)
                                .font(.caption)
                                .padding([.horizontal], 15)
                                .padding([.vertical], 5)
                                .glassEffect()
                            Spacer()
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Capture Button
                    ZStack {
                        Circle()
                            .glassEffect()
                        Button(action: { camera.takePhoto() }) {
                            Circle()
                                .inset(by: 8)
                                .fill(.white)
                        }
                        .accessibilityLabel("Take Photo")
                        .buttonStyle(.plain)
                    }
                    .frame(width: 80, height: 80)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                if !isLockedMode {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Group {
                        Button("Toggle Flash", systemImage: camera.flashMode.systemImage) {
                            camera.toggleFlash()
                        }
                        .accessibilityValue(camera.flashMode.accessibilityValue)
                        
                        Button("Switch Lens", systemImage: "camera.aperture") {
                            camera.switchLens()
                        }
                        
                        Button("Switch Camera", systemImage: "arrow.triangle.2.circlepath.camera") {
                            camera.switchCamera()
                        }
                    }
                }
            } // toolbar
            .accessibilityAction(.escape) { dismiss() }
        } // NavigationStack
        .accessibilityAction(.magicTap) { camera.takePhoto() }
        .onChange(of: camera.cameraPermission) {
            updateAlertMessage()
        }
        .onAppear {
            #if !EXTENSION
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            camera.startSession()
            camera.onPhotoCaptured = { data in
                onSave(data)
                if !remainAfterCapture {
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            }
            updateAlertMessage()
        }
        .onDisappear {
            #if !EXTENSION
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
            camera.stopSession()
        }
    }
    
    // Set permission error messages
    private func updateAlertMessage() {
        switch camera.cameraPermission {
        case .authorized:
            if isLockedMode {
                alertMessage = "You are on the lock screen. You can check photos taken after unlocking your device."
            } else {
                alertMessage = nil
            }
        case .notDetermined:
            alertMessage = "Please allow camera access to take photos."
        case .denied:
            alertMessage = "Camera access is denied. Please grant permission in Settings."
        case .restricted:
            alertMessage = "Camera access is restricted."
        default:
            alertMessage = "Cannot access the camera."
        }
    }
}

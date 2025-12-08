//
//  CameraView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import SwiftUI
import AVFoundation
import AVKit
import Photos

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) var dismiss
    
    var isLockedMode: Bool = false
    var onSave: (Data) -> Void
    @State private var alertMessage: LocalizedStringResource? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                #if targetEnvironment(simulator)
                Text("Camera is not available in the Simulator")
                    .foregroundColor(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                #else
                if viewModel.cameraPermission == .authorized {
                    CameraPreview(session: viewModel.session) { point in
                        viewModel.focus(at: point)
                    }
                    .ignoresSafeArea()
                    .opacity(viewModel.shouldFlashScreen ? 0 : 1)
                    .onCameraCaptureEvent(defaultSoundDisabled: true) { event in
                        if event.phase == .began {
                            viewModel.takePhoto()
                        }
                    }
                }
                #endif
                
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
                            .frame(width: 72, height: 72)
                        Button(action: { viewModel.takePhoto() }) {
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                        .accessibilityLabel("Take Photo")
                        .disabled(viewModel.cameraPermission != .authorized)
                        .opacity(viewModel.cameraPermission == .authorized ? 1.0 : 0.5)
                    }
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
                    Button("Toggle Flash", systemImage: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash") {
                        viewModel.toggleFlash()
                    }
                    .accessibilityValue(viewModel.isFlashOn ? "Flash is On" : "Flash is Off")
                    Button("Switch Lens", systemImage: "camera.aperture") {
                        viewModel.switchLens()
                    }
                    Button("Switch Camera", systemImage: "arrow.triangle.2.circlepath.camera") {
                        viewModel.switchCamera()
                    }
                }
            }
            .onChange(of: viewModel.cameraPermission) {
                updateAlertMessage()
            }
            .onAppear {
                viewModel.startSession()
                viewModel.onPhotoCaptured = { data in
                    onSave(data)
                    if !viewModel.remainCameraAfterCapture {
                        dismiss()
                    }
                }
                updateAlertMessage()
            }
            .onDisappear {
                viewModel.stopSession()
            }
        }
    }
    
    // Set permission error messages
    private func updateAlertMessage() {
        switch viewModel.cameraPermission {
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
            alertMessage = "Camera access is might not be granted."
        }
    }
}

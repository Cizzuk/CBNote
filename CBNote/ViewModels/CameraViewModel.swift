//
//  CameraViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import Combine
import Photos
import SwiftUI

class CameraViewModel: ObservableObject {
    @Published var camera = Camera()
    @Published var shouldFlashScreen = false
    
    var onPhotoCaptured: ((Data) -> Void)? {
        get { camera.onPhotoCaptured }
        set { camera.onPhotoCaptured = newValue }
    }
    
    var session: AVCaptureSession {
        camera.session
    }
    
    var isFlashOn: Bool {
        camera.isFlashOn
    }
    
    var cameraPermission: AVAuthorizationStatus {
        camera.cameraPermission
    }

    var isCameraReady: Bool {
        camera.isSessionReady
    }
    
    var remainCameraAfterCapture: Bool {
        UserDefaults.standard.bool(forKey: "remainCameraAfterCapture")
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Forward changes from Camera to CameraViewModel
        camera.$isFlashOn
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        camera.$session
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        camera.$cameraPermission
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        camera.$isSessionReady
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    func switchCamera() {
        guard isCameraReady else { return }
        camera.switchCamera()
    }
    
    func switchLens() {
        guard isCameraReady else { return }
        camera.switchLens()
    }
    
    func takePhoto() {
        guard isCameraReady else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.1)) {
            shouldFlashScreen = false
        }
        camera.takePhoto()
    }
    
    func toggleFlash() {
        guard isCameraReady else { return }
        camera.toggleFlash()
    }
    
    func focus(at point: CGPoint) {
        guard isCameraReady else { return }
        camera.focus(at: point)
    }
    
    func startSession() {
        camera.startSession()
    }

    func stopSession() {
        camera.stopSession()
    }
}

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
        
        camera.$photoLibraryPermission
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    func switchCamera() {
        camera.switchCamera()
    }
    
    func switchLens() {
        camera.switchLens()
    }
    
    func takePhoto() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.1)) {
            shouldFlashScreen = false
        }
        camera.takePhoto()
    }
    
    func toggleFlash() {
        camera.toggleFlash()
    }
    
    func focus(at point: CGPoint) {
        camera.focus(at: point)
    }
    
    func startSession() {
        camera.startSession()
    }

    func stopSession() {
        camera.stopSession()
    }
}

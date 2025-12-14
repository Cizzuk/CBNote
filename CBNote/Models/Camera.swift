//
//  Camera.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import Combine
import Photos
import UIKit

class Camera: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isFlashOn = false
    @Published var cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var photoLibraryPermission = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    
    private let output = AVCapturePhotoOutput()
    private var input: AVCaptureDeviceInput?
    private var controlsDelegate = CaptureControlsDelegate()
    
    private let backCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .back
    )
    private let frontCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .front
    )
    private let externalCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external],
        mediaType: .video,
        position: .unspecified
    )
    
    var onPhotoCaptured: ((Data) -> Void)?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraPermission {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupSession()
                    }
                    self.cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            session.sessionPreset = .high
        default:
            session.sessionPreset = .photo
        }
        
        // Setup default input
        DispatchQueue.global(qos: .userInitiated).async {
            if let backCamera = self.backCameraDiscoverySession.devices.first {
                self.setupInput(for: backCamera)
            } else if let frontCamera = self.frontCameraDiscoverySession.devices.first {
                self.setupInput(for: frontCamera)
            } else if let externalCamera = self.externalCameraDiscoverySession.devices.first {
                self.setupInput(for: externalCamera)
            }
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    // Setup new camera or lens input
    private func setupInput(for device: AVCaptureDevice) {
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            if let currentInput = input {
                session.removeInput(currentInput)
            }
            
            // Remove old controls
            for control in session.controls {
                session.removeControl(control)
            }
            
            // Add new controls for Camera Control
            let controls = [
                AVCaptureSystemZoomSlider(device: device),
                AVCaptureSystemExposureBiasSlider(device: device),
            ]
            
            for control in controls {
                if session.canAddControl(control) {
                    session.addControl(control)
                }
            }
            
            // Set controls delegate
            let sessionQueue = DispatchSerialQueue(label: "cameraControlSessionQueue")
            session.setControlsDelegate(controlsDelegate, queue: sessionQueue)
            
            if session.canAddInput(newInput) {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.session.addInput(newInput)
                    self.input = newInput
                }
            }
        } catch {
            print("Error setting up input: \(error)")
        }
    }
    
    // Returns all available cameras on device
    private var availableCameras: [AVCaptureDevice] {
        var cameras: [AVCaptureDevice] = []
        if let backCamera = backCameraDiscoverySession.devices.first {
            cameras.append(backCamera)
        }
        if let frontCamera = frontCameraDiscoverySession.devices.first {
            cameras.append(frontCamera)
        }
        if let externalCamera = externalCameraDiscoverySession.devices.first {
            cameras.append(externalCamera)
        }
        return cameras
    }

    func switchCamera() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Get current camera(device)
        guard let currentInput = input else { return }
        let currentDevice = currentInput.device
        
        // Get all available cameras
        let cameras = availableCameras
        guard !cameras.isEmpty else { return }
        
        let currentCategoryIndex: Int?
        
        // Find the index of current camera in available cameras
        if currentDevice.position == .back {
             currentCategoryIndex = cameras.firstIndex { $0.position == .back }
        } else if currentDevice.position == .front {
             currentCategoryIndex = cameras.firstIndex { $0.position == .front }
        } else {
             currentCategoryIndex = cameras.firstIndex { $0.position == .unspecified }
        }
        
        // Determine next camera
        var nextCamera: AVCaptureDevice?
        if let index = currentCategoryIndex {
            let nextIndex = (index + 1) % cameras.count
            nextCamera = cameras[nextIndex]
        } else {
            // If current camera not found, switch to first available camera
            nextCamera = cameras.first
        }
        
        if let nextCamera = nextCamera {
            setupInput(for: nextCamera)
        }
    }
    
    func switchLens() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Get current camera(device)
        guard let currentInput = input else { return }
        let currentDevice = currentInput.device
        let currentPosition = currentDevice.position
        
        // Get lenses for current camera(position)
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: currentPosition)
        let lenses = discoverySession.devices
        
        guard !lenses.isEmpty else { return }
        
        var nextDevice: AVCaptureDevice?
        
        // Determine next lens
        if let currentIndex = lenses.firstIndex(of: currentDevice) {
            let nextIndex = (currentIndex + 1) % lenses.count
            nextDevice = lenses[nextIndex]
        } else {
            nextDevice = lenses.first
        }
        
        if let nextDevice = nextDevice {
            setupInput(for: nextDevice)
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func focus(at point: CGPoint) {
        guard let device = input?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.isSubjectAreaChangeMonitoringEnabled = true
            device.unlockForConfiguration()
        } catch {
            print("Error focusing: \(error)")
        }
    }
    
    // Update rotation angle based on device orientation
    func updateRotationAngle() {
        guard let device = input?.device else { return }
        let rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
        let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        session.connections.forEach { $0.videoRotationAngle = angle }
    }
    
    func takePhoto() {
        updateRotationAngle()
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

extension Camera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108) // 1108: shutter sound
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let data = photo.fileDataRepresentation() else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.onPhotoCaptured?(data)
        }
    }
}

class CaptureControlsDelegate: NSObject, AVCaptureSessionControlsDelegate {
    
    @Published private(set) var isShowingFullscreenControls = false

    func sessionControlsDidBecomeActive(_ session: AVCaptureSession) { }

    func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) { }
    
    func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) { }
    
    func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) { }
}


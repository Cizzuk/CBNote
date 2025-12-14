//
//  Settings.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import AppIntents
import Combine
import UIKit

class SettingsViewModel: ObservableObject {
    @Published var autoPasteWhenOpening: Bool = UserDefaults.standard.bool(forKey: "autoPasteWhenOpening") {
        didSet {
            UserDefaults.standard.set(autoPasteWhenOpening, forKey: "autoPasteWhenOpening")
        }
    }
    
    @Published var remainCameraAfterCapture: Bool = UserDefaults.standard.bool(forKey: "remainCameraAfterCapture") {
        didSet {
            UserDefaults.standard.set(remainCameraAfterCapture, forKey: "remainCameraAfterCapture")
        }
    }
        
    @Published var nameFormat: String = UserDefaults.standard.string(forKey: "nameFormat") ?? "yyyy-MM-dd-HH-mm-ss" {
        didSet {
            if nameFormat.isEmpty {
                nameFormat = "yyyy-MM-dd-HH-mm-ss"
            }
            UserDefaults.standard.set(nameFormat, forKey: "nameFormat")
        }
    }
    
    @Published var cameraControlAction: OpenAppOption = {
        if let rawValue = UserDefaults.standard.string(forKey: "cameraControlAction"),
           let action = OpenAppOption(rawValue: rawValue) {
            return action
        }
        return .launchCamera
    }() {
        didSet {
            UserDefaults.standard.set(cameraControlAction.rawValue, forKey: "cameraControlAction")
        }
    }

    @Published var captureLaunchAction: CaptureContext.LaunchAction = .launchCamera {
        didSet {
            Task {
                let context = CaptureContext(launchAction: captureLaunchAction)
                do {
                    try await CaptureIntent.updateAppContext(context)
                } catch {
                    print("Failed to update app context: \(error)")
                }
            }
        }
    }

    @Published var doesDeviceHaveCameraControl: Bool = {
        let device = UIDevice.current.userInterfaceIdiom
        return device == .phone
    }()

    init() {
        Task {
            if let context = try? await CaptureIntent.appContext {
                await MainActor.run {
                    self.captureLaunchAction = context.launchAction
                }
            }
        }
    }
}

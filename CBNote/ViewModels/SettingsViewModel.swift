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
    // MARK: - When App Opening
    @Published var autoPasteWhenOpening: Bool = UserDefaults.standard.bool(forKey: "autoPasteWhenOpening") {
        didSet {
            UserDefaults.standard.set(autoPasteWhenOpening, forKey: "autoPasteWhenOpening")
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
            CaptureContext.syncContextSettings()
        }
    }
    
    @Published var cameraControlActionOpenURL: String = UserDefaults.standard.string(forKey: "cameraControlActionOpenURL") ?? "" {
        didSet {
            UserDefaults.standard.set(cameraControlActionOpenURL, forKey: "cameraControlActionOpenURL")
        }
    }
    
    // MARK: - Camera
    @Published var remainCameraAfterCapture: Bool = UserDefaults.standard.bool(forKey: "remainCameraAfterCapture") {
        didSet {
            UserDefaults.standard.set(remainCameraAfterCapture, forKey: "remainCameraAfterCapture")
        }
    }
    
    @Published var saveCapturedImageToPhotos: Bool = UserDefaults.standard.bool(forKey: "saveCapturedImageToPhotos") {
        didSet {
            UserDefaults.standard.set(saveCapturedImageToPhotos, forKey: "saveCapturedImageToPhotos")
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
    
    // MARK: - Note List Settings
    @Published var showImagePreview: Bool = {
        let value = UserDefaults.standard.object(forKey: "showImagePreview")
        return value == nil ? true : UserDefaults.standard.bool(forKey: "showImagePreview")
    }() {
        didSet {
            UserDefaults.standard.set(showImagePreview, forKey: "showImagePreview")
        }
    }
    
    @Published var showHiddenFiles: Bool = UserDefaults.standard.bool(forKey: "showHiddenFiles") {
        didSet {
            UserDefaults.standard.set(showHiddenFiles, forKey: "showHiddenFiles")
        }
    }
    
    @Published var enableNoteListAnimations: Bool = UserDefaults.standard.bool(forKey: "enableNoteListAnimations") {
        didSet {
            UserDefaults.standard.set(enableNoteListAnimations, forKey: "enableNoteListAnimations")
        }
    }
    
    // MARK: - File Name Format
    @Published var nameFormat: String = UserDefaults.standard.string(forKey: "nameFormat") ?? "yyyy-MM-dd-HH-mm-ss" {
        didSet {
            if nameFormat.isEmpty {
                nameFormat = "yyyy-MM-dd-HH-mm-ss"
            }
            UserDefaults.standard.set(nameFormat, forKey: "nameFormat")
        }
    }
    
    // MARK: - Search Engine
    @Published var searchEngine: String = UserDefaults.standard.string(forKey: "searchEngine") ?? TrueDevice.defaultSearchEngine
    {
        didSet {
            UserDefaults.standard.set(searchEngine, forKey: "searchEngine")
        }
    }
    
    // Initialize
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

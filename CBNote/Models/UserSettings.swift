//
//  UserSettings.swift
//  CBNote
//
//  Created by Cizzuk on 2026/03/28.
//

import Combine
import Foundation

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    private init() {}
    
    private enum Keys {
        static let autoPasteWhenOpening = "autoPasteWhenOpening"
        static let cameraControlAction = "cameraControlAction"
        static let cameraControlActionOpenURL = "cameraControlActionOpenURL"
        static let remainCameraAfterCapture = "remainCameraAfterCapture"
        static let saveCapturedImageToPhotos = "saveCapturedImageToPhotos"
        static let imagePreviewMode = "imagePreviewMode"
        static let showHiddenFiles = "showHiddenFiles"
        static let enableNoteListAnimations = "enableNoteListAnimations"
        static let nameFormat = "nameFormat"
        static let searchEngine = "searchEngine"
        static let documentDir = "documentDir"
        static let sortKey = "sortKey"
        static let sortDirection = "sortDirection"
    }
    
    @Published var autoPasteWhenOpening: Bool = UserDefaults.standard.bool(forKey: Keys.autoPasteWhenOpening) {
        didSet {
            UserDefaults.standard.set(autoPasteWhenOpening, forKey: Keys.autoPasteWhenOpening)
        }
    }
    
    @Published var cameraControlAction: OpenAppOption = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.cameraControlAction),
           let action = OpenAppOption(rawValue: rawValue) {
            return action
        }
        return .launchCamera
    }() {
        didSet {
            UserDefaults.standard.set(cameraControlAction.rawValue, forKey: Keys.cameraControlAction)
            CaptureContext.syncContextSettings()
        }
    }
    
    @Published var cameraControlActionOpenURL: String = UserDefaults.standard.string(forKey: Keys.cameraControlActionOpenURL) ?? "" {
        didSet {
            UserDefaults.standard.set(cameraControlActionOpenURL, forKey: Keys.cameraControlActionOpenURL)
        }
    }
    
    @Published var remainCameraAfterCapture: Bool = UserDefaults.standard.bool(forKey: Keys.remainCameraAfterCapture) {
        didSet {
            UserDefaults.standard.set(remainCameraAfterCapture, forKey: Keys.remainCameraAfterCapture)
        }
    }
    
    @Published var saveCapturedImageToPhotos: Bool = UserDefaults.standard.bool(forKey: Keys.saveCapturedImageToPhotos) {
        didSet {
            UserDefaults.standard.set(saveCapturedImageToPhotos, forKey: Keys.saveCapturedImageToPhotos)
        }
    }
    
    @Published var imagePreviewMode: ImagePreviewMode = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.imagePreviewMode),
           let mode = ImagePreviewMode(rawValue: rawValue) {
            return mode
        }
        
        // Migrate from old setting
        let oldSettingKey = "showImagePreview"
        if UserDefaults.standard.object(forKey: oldSettingKey) == nil {
            return .default
        } else {
            return UserDefaults.standard.bool(forKey: oldSettingKey) ? .large : .off
        }
    }() {
        didSet {
            UserDefaults.standard.set(imagePreviewMode.rawValue, forKey: Keys.imagePreviewMode)
        }
    }
    
    @Published var showHiddenFiles: Bool = UserDefaults.standard.bool(forKey: Keys.showHiddenFiles) {
        didSet {
            UserDefaults.standard.set(showHiddenFiles, forKey: Keys.showHiddenFiles)
        }
    }
    
    @Published var enableNoteListAnimations: Bool = UserDefaults.standard.bool(forKey: Keys.enableNoteListAnimations) {
        didSet {
            UserDefaults.standard.set(enableNoteListAnimations, forKey: Keys.enableNoteListAnimations)
        }
    }
    
    @Published var nameFormat: String = UserDefaults.standard.string(forKey: Keys.nameFormat) ?? "yyyy-MM-dd-HH-mm-ss" {
        didSet {
            if nameFormat.isEmpty {
                nameFormat = "yyyy-MM-dd-HH-mm-ss"
            }
            UserDefaults.standard.set(nameFormat, forKey: Keys.nameFormat)
        }
    }
    
    @Published var searchEngine: String = UserDefaults.standard.string(forKey: Keys.searchEngine) ?? TrueDevice.defaultSearchEngine {
        didSet {
            UserDefaults.standard.set(searchEngine, forKey: Keys.searchEngine)
        }
    }
    
    @Published var documentDir: DocumentDir = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.documentDir),
           let dir = DocumentDir(rawValue: rawValue) {
            return dir
        }
        return .defaultDir
    }() {
        didSet {
            UserDefaults.standard.set(documentDir.rawValue, forKey: Keys.documentDir)
        }
    }
    
    @Published var sortKey: SortKey = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.sortKey),
           let key = SortKey(rawValue: rawValue) {
            return key
        }
        return .name
    }() {
        didSet {
            UserDefaults.standard.set(sortKey.rawValue, forKey: Keys.sortKey)
        }
    }
    
    @Published var sortDirection: SortDirection = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.sortDirection),
           let direction = SortDirection(rawValue: rawValue) {
            return direction
        }
        return .descending
    }() {
        didSet {
            UserDefaults.standard.set(sortDirection.rawValue, forKey: Keys.sortDirection)
        }
    }
}

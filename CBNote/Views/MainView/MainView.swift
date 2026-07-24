//
//  MainView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import QuickLook
import PhotosUI
import SwiftUI
import Translation
import TemporaryScreenCurtain

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion
    @StateObject var vm = MainViewModel()
    @ObservedObject private var userSettings = UserSettings.shared
    
    @State var previewURL: URL?
    @State var isExpandPinnedSection = true
    @State var showFileImporter = false
    @State var selectedPhoto: PhotosPickerItem? = nil
    
    var imagePreviewMode: ImagePreviewMode { userSettings.imagePreviewMode }
    var enableNoteListAnimations: Bool { userSettings.enableNoteListAnimations }
    
    @Namespace var ns_settingsView
    let id_openSettingsButton = "openSettingsButton"

    var body: some View {
        NavigationStack {
            fileListView()
                // MARK: - View Config
                .searchable(text: $vm.searchQuery, prompt: "Search Notes")
                .toolbar { toolbarContent }
                .quickLookPreview($previewURL)
                #if !targetEnvironment(macCatalyst)
                .translationPresentation(isPresented: $vm.showTranslation, text: vm.translationText)
                #endif
                // MARK: - Modals
                .fullScreenCover(isPresented: $vm.showCamera) {
                    CameraView(remainAfterCapture: userSettings.remainCameraAfterCapture) { data in
                        vm.saveCapturedImage(data: data)
                    }
                }
                .sheet(isPresented: $vm.showRecorder) {
                    RecorderView { url in
                        vm.saveRecordedAudio(from: url)
                    }
                }
                .sheet(isPresented: $vm.showSettings) {
                    SettingsView()
                        .navigationTransition(.zoom(
                            sourceID: id_openSettingsButton,
                            in: ns_settingsView
                        ))
                }
                .alert("Rename", isPresented: $vm.isRenaming) {
                    TextField("New Name", text: $vm.newName)
                    Button("Cancel", role: .cancel) {}
                    Button("Rename", role: .confirm) {
                        vm.renameFile()
                    }
                    .disabled(!vm.isValidFileName(vm.newName))
                }
                .alert("Failed to Import File", isPresented: $vm.showFileImportError) {
                    Button("OK", role: .close) {}
                }
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: true
                ) { result in
                    vm.handleFileImporter(result)
                }
                // MARK: - Events
                .onAppear { vm.onAppear() }
                .onChange(of: scenePhase) { vm.onChange(scenePhase: scenePhase) }
                .onChange(of: selectedPhoto) {
                    if let selectedPhoto {
                        vm.handlePhotoPickerSelection(selectedPhotos)
                    }
                    selectedPhoto = nil
                }
                // Opening from Camera Control
                .onReceive(NotificationCenter.default.publisher(for: .cameraControlDidActivate)) { _ in
                    vm.handleCameraControlAction()
                }
                // Opening from Capture Extension
                .onContinueUserActivity("net.cizzuk.cbnote.CaptureExtension.runCameraControlAction") { activity in
                    vm.handleCameraControlAction(shouldOpenDummyCamera: false)
                }
                // Opening from App Intents (Shortcuts, Control Center, Home Screen Shortcut)
                .onReceive(NotificationCenter.default.publisher(for: .openAppIntentPerformed)) { action in
                    if let option = action.object as? OpenAppOption {
                        vm.openApp(with: option)
                    }
                }
                // Keyboard Shortcuts
                .onReceive(NotificationCenter.default.publisher(for: .customKeyboardShortcutPerformed)) { action in
                    if let shortcut = action.object as? CustomKeyboardShortcut {
                        vm.handleKeyboardShortcut(shortcut: shortcut)
                    }
                }
                .onOpenURL { url in
                    vm.handleOpenURL(url: url)
                }
        } // NavigationStack
        // MARK: - Temporary Screen Curtain
        .temporaryScreenCurtain(isPresented: $vm.showTmpCurtain)
    }
}

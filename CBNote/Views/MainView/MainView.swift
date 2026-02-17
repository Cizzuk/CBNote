//
//  MainView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import QuickLook
import SwiftUI
import Translation
import TemporaryScreenCurtain

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion
    @StateObject var viewModel = MainViewModel()
    
    @State var previewURL: URL?
    @State var isExpandPinnedSection = true
    @State var showFileImporter = false
    
    @AppStorage("showImagePreview") var showImagePreview: Bool = true
    @AppStorage("enableNoteListAnimations") var enableNoteListAnimations: Bool = false
    
    @Namespace var ns_settingsView
    let id_openSettingsButton = "openSettingsButton"

    var body: some View {
        NavigationStack {
            fileListView()
                // MARK: - View Config
                .searchable(text: $viewModel.searchQuery, prompt: "Search Notes")
                .toolbar { toolbarContent }
                .quickLookPreview($previewURL)
                #if !targetEnvironment(macCatalyst)
                .translationPresentation(isPresented: $viewModel.showTranslation, text: viewModel.translationText)
                #endif
                // MARK: - Modals
                .fullScreenCover(isPresented: $viewModel.showCamera) {
                    CameraView { data in
                        viewModel.saveCapturedImage(data: data)
                    }
                }
                .sheet(isPresented: $viewModel.showRecorder) {
                    RecorderView { url in
                        viewModel.saveRecordedAudio(from: url)
                    }
                }
                .sheet(isPresented: $viewModel.showSettings) {
                    SettingsView()
                        .navigationTransition(.zoom(
                            sourceID: id_openSettingsButton,
                            in: ns_settingsView
                        ))
                }
                .alert("Rename", isPresented: $viewModel.isRenaming) {
                    TextField("New Name", text: $viewModel.newName)
                    Button("Cancel", role: .cancel) {}
                    Button("Rename", role: .confirm) {
                        viewModel.renameFile()
                    }
                    .disabled(!viewModel.isValidFileName(viewModel.newName))
                }
                .alert("Failed to Import File", isPresented: $viewModel.showFileImportError) {
                    Button("OK", role: .close) {}
                }
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: true
                ) { result in
                    viewModel.handleFileImporter(result)
                }
                // MARK: - Events
                .onAppear { viewModel.onAppear() }
                .onChange(of: scenePhase) { viewModel.onChange(scenePhase: scenePhase) }
                // Opening from Camera Control
                .onReceive(NotificationCenter.default.publisher(for: .cameraControlDidActivate)) { _ in
                    viewModel.handleCameraControlAction()
                }
                // Opening from Capture Extension
                .onContinueUserActivity("net.cizzuk.cbnote.CaptureExtension.runCameraControlAction") { activity in
                    viewModel.handleCameraControlAction(shouldOpenDummyCamera: false)
                }
                // Opening from App Intents (Shortcuts, Control Center, Home Screen Shortcut)
                .onReceive(NotificationCenter.default.publisher(for: .openAppIntentPerformed)) { action in
                    if let option = action.object as? OpenAppOption {
                        viewModel.openApp(with: option)
                    }
                }
                // Keyboard Shortcuts
                .onReceive(NotificationCenter.default.publisher(for: .customKeyboardShortcutPerformed)) { action in
                    if let shortcut = action.object as? CustomKeyboardShortcut {
                        viewModel.handleKeyboardShortcut(shortcut: shortcut)
                    }
                }
                .onOpenURL { url in
                    viewModel.handleOpenURL(url: url)
                }
        } // NavigationStack
        // MARK: - Temporary Screen Curtain
        .temporaryScreenCurtain(isPresented: $viewModel.showTmpCurtain)
    }
}

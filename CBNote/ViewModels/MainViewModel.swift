//
//  MainViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import Combine
import LockedCameraCapture
import Photos
import SwiftUI
import Translation
import UniformTypeIdentifiers

extension Notification.Name {
    static let noteListRefreshAttempt = Notification.Name("noteListRefreshAttempt")
}

class MainViewModel: ObservableObject {
    @Published var showTmpCurtain: Bool = false
    
    @Published var pinnedFiles: [URL] = []
    @Published var unpinnedFiles: [URL] = []
    
    @Published var documentDir: DocumentDir = .onDevice
    @Published var sortKey: SortKey = .name
    @Published var sortDirection: SortDirection = .descending
    
    @Published var searchQuery = ""
    @Published var newFileURLToScroll: URL?
    
    @Published var showPasteError = false
    @Published var showCamera = false
    @Published var showRecorder = false
    @Published var showSettings = false
    @Published var showFileImportError = false
    
    @Published var renamingURL: URL?
    @Published var newName = ""
    @Published var isRenaming = false
    
    @Published var showTranslation = false
    @Published var translationText = ""
    
    let noteManager = NoteManager()
    private let dummyCameraManager = DummyCameraManager.shared
    private let userSettings = UserSettings.shared
    
    private var lastPasteboardChangeCount: Int = -1
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Publishers.CombineLatest(noteManager.$pinnedFiles, $searchQuery)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] files, query in
                self?.pinnedFiles = self?.filterFiles(files, query: query) ?? []
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(noteManager.$unpinnedFiles, $searchQuery)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] files, query in
                self?.unpinnedFiles = self?.filterFiles(files, query: query) ?? []
            }
            .store(in: &cancellables)
        
        noteManager.$documentDir
            .sink { [weak self] dir in
                self?.documentDir = dir
                self?.userSettings.documentDir = dir
            }
            .store(in: &cancellables)
        
        if !documentDir.isAvailable {
            noteManager.setDocumentDir(type: .defaultDir)
        }
        
        noteManager.$sortKey
            .sink { [weak self] key in
                self?.sortKey = key
                self?.userSettings.sortKey = key
            }
            .store(in: &cancellables)
        
        noteManager.$sortDirection
            .sink { [weak self] direction in
                self?.sortDirection = direction
                self?.userSettings.sortDirection = direction
            }
            .store(in: &cancellables)
    }
    
    private func filterFiles(_ files: [URL], query: String) -> [URL] {
        var filteredFiles = files
        
        // Hidden file filter
        let showHiddenFiles = userSettings.showHiddenFiles
        if !showHiddenFiles {
            filteredFiles = filteredFiles.filter { !$0.lastPathComponent.hasPrefix(".") }
        }
        
        // Query filter
        if !query.isEmpty {
            filteredFiles = filteredFiles.filter { url in
                // File name search
                if url.lastPathComponent.localizedCaseInsensitiveContains(query) {
                    return true
                }
                
                // File content search
                if FileTypes.isEditableText(url) {
                    if let content = try? String(contentsOf: url, encoding: .utf8),
                       content.localizedCaseInsensitiveContains(query) {
                        return true
                    }
                }
                
                return false
            }
        }
        
        return filteredFiles
    }
    
    func onAppear() {
        checkLockedCameraCaptures()
        checkAutoPaste()
        loadFiles()
    }
    
    func onChange(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            checkLockedCameraCaptures()
            checkAutoPaste()
            loadFiles()
            refreshFiles()
            
            if !showRecorder {
                RecorderActivityManager.endAll()
            }
        case .inactive:
            break
        case .background:
            dummyCameraManager.close()
        @unknown default:
            break
        }
    }
    
    // MARK: - NoteManager Actions
    
    func loadFiles() {
        noteManager.loadFiles()
    }
    
    func refreshFiles() {
        checkLockedCameraCaptures()
        loadFiles()
        NotificationCenter.default.post(name: .noteListRefreshAttempt, object: nil)
    }
    
    func setDocumentDir(type: DocumentDir) {
        noteManager.setDocumentDir(type: type)
    }
    
    func toggleSort(key: SortKey) {
        var newDirection = sortDirection
        if sortKey == key {
            newDirection = sortDirection == .descending ? .ascending : .descending
        } else {
            newDirection = .descending
        }
        noteManager.setSort(key: key, direction: newDirection)
    }
    
    // MARK: - Clipboard Management
    
    func addAndPaste(suppressError: Bool = false) {
        ClipboardManager.newNoteFromClipboard(
            noteManager: noteManager,
            completion: { [weak self] result in
                switch result {
                case .success(let url):
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self?.lastPasteboardChangeCount = UIPasteboard.general.changeCount
                    self?.noteManager.loadFiles()
                    DispatchQueue.main.async {
                        self?.newFileURLToScroll = url
                    }
                case .failure:
                    self?.showPasteError = true
                    if !suppressError {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            }
        )
    }
    
    func checkAutoPaste() {
        if userSettings.autoPasteWhenOpening && lastPasteboardChangeCount != UIPasteboard.general.changeCount {
            addAndPaste(suppressError: true)
        }
    }
    
    func copyFile(at url: URL) {
        ClipboardManager.copyFile(at: url)
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
    }
    
    // MARK: - Note Management
    
    func createNewNote() {
        guard let newNoteURL = noteManager.createNewNote() else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        newFileURLToScroll = newNoteURL
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func saveNewFile(from url: URL) {
        guard let destURL = noteManager.saveNewFile(from: url) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        newFileURLToScroll = destURL
    }
    
    func isFilePinned(_ url: URL) -> Bool {
        noteManager.isPinned(url)
    }
    
    func pinUnpinFile(at url: URL) {
        noteManager.togglePin(for: url)
    }
    
    func unpinAll() {
        noteManager.unpinAll()
    }
    
    func isValidFileName(_ name: String) -> Bool {
        noteManager.isValidFileName(name)
    }
    
    func startRenaming(at url: URL) {
        renamingURL = url
        newName = url.lastPathComponent
        isRenaming = true
    }
    
    func renameFile() {
        guard let url = renamingURL else { return }
        noteManager.renameFile(at: url, newName: newName)
    }
    
    func deleteFile(at url: URL) {
        noteManager.deleteFile(at: url)
    }
    
    // MARK: - Special Note Actions
    
    func translateFile(at url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        translationText = content
        showTranslation = true
    }
    
    func openInBrowser(at url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        
        // If content is a valid URL, open directly
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        // Check only one line
        if !trimmedContent.contains("\n") {
            // Check valid URL
            if let linkURL = URL(string: trimmedContent), UIApplication.shared.canOpenURL(linkURL) {
                UIApplication.shared.open(linkURL)
                return
            }
        }
        
        // Otherwise, search in Browser
        if let encodedQuery = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            // Create Search URL
            let searchEngine = userSettings.searchEngine
            let queryURLString = searchEngine.replacingOccurrences(of: "%s", with: encodedQuery)
            if let searchURL = URL(string: queryURLString) {
                UIApplication.shared.open(searchURL)
            }
        }
    }
    
    func saveImageToPhotos(at url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard TrueDevice.isSaveToPhotosAllowed() else {
                print("saveImageToPhotos: Save to Photos not available")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }
            
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                print("saveImageToPhotos: Unable to load image data")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }
            
            // Save
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if !success, let error = error {
                    print("saveImageToPhotos: ", error)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            })
        }
    }
    
    // MARK: - Handlers
    
    // Handler for camera capture
    func saveCapturedImage(data: Data, suppress: Bool = false) {
        // Save as new note
        guard let newImageURL = noteManager.saveCapturedImage(data: data) else {
            if !suppress {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            return
        }
        
        // Scroll
        if !suppress {
            DispatchQueue.main.async {
                self.newFileURLToScroll = newImageURL
            }
        }
        
        // Save to Photos if needed
        if userSettings.saveCapturedImageToPhotos {
            saveImageToPhotos(at: newImageURL)
        }
    }
    
    // Handler for locked camera captures
    func checkLockedCameraCaptures() {
        #if !targetEnvironment(macCatalyst)
        DispatchQueue.global(qos: .utility).async {
            let urls = LockedCameraCaptureManager.shared.sessionContentURLs
            guard !urls.isEmpty else { return }
            
            for url in urls {
                guard
                    let fileURLs = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil),
                    !fileURLs.isEmpty
                else { continue }
                
                for fileURL in fileURLs {
                    if let data = try? Data(contentsOf: fileURL) {
                        self.saveCapturedImage(data: data, suppress: true)
                    }
                }
                
                DispatchQueue.global(qos: .background).async {
                    Task { try? await LockedCameraCaptureManager.shared.invalidateSessionContent(at: url) }
                }
            }
            
            self.loadFiles()
        }
        #endif
    }
    
    // Handler for audio recorder
    func saveRecordedAudio(from sourceURL: URL) {
        guard let destURL = noteManager.createFileURL(fileExtension: "m4a") else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destURL)
            newFileURLToScroll = destURL
            loadFiles()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("saveRecordedAudio error: ", error)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    // Handle file importer
    func handleFileImporter(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                saveNewFile(from: url)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .failure(let error):
            print("File import error: ", error)
            showFileImportError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    // Handler for keyboard shortcuts
    func handleKeyboardShortcut(shortcut: CustomKeyboardShortcut) {
        switch shortcut {
        case .openSettings:
            showSettings = true
        case .reloadFiles:
            refreshFiles()
        case .addNewNote:
            createNewNote()
        case .pasteFromClipboard:
            addAndPaste()
        }
    }
    
    // Handler for URL scheme
    func handleOpenURL(url: URL) {
        if let option = OpenAppOption.urlToOption(url) {
            openApp(with: option)
        }
    }
    
    // Handler for launch from camera control
    func handleCameraControlAction(shouldOpenDummyCamera: Bool = true) {
        guard TrueDevice.isCamControlAvailable else { return }
        
        let action = userSettings.cameraControlAction
        
        openApp(with: action, shouldOpenDummyCamera: shouldOpenDummyCamera)
    }
    
    func openApp(
        with action: OpenAppOption,
        shouldOpenDummyCamera: Bool = false,
        allowCBNoteURLScheme: Bool = true)
    {
        func openDummyCameraIfNeeded() {
            if shouldOpenDummyCamera && UIApplication.shared.applicationState != .active {
                dummyCameraManager.open()
            }
        }
        
        // Open Dummy Camera if action needs it
        if action.shouldOpenDummyCamera {
            openDummyCameraIfNeeded()
        }
        
        showSettings = false
        showCamera = false
        showRecorder = false
        
        switch action {
        case .launchCamera:
            showCamera = true
            
        case .pasteFromClipboard:
            addAndPaste()
            
        case .addNewNote:
            createNewNote()
            
        case .startRecording:
            showRecorder = true
            
        case .openAppOnly:
            break
            
        case .openURL:
            guard !userSettings.cameraControlActionOpenURL.isEmpty,
                let url = URL(string: userSettings.cameraControlActionOpenURL) else {
                openDummyCameraIfNeeded()
                return
            }
            
            // If URL is CBNote's URL scheme
            if let option = OpenAppOption.urlToOption(url) {
                guard allowCBNoteURLScheme else {
                    openDummyCameraIfNeeded()
                    return
                }
                openApp(
                    with: option,
                    shouldOpenDummyCamera: shouldOpenDummyCamera,
                    allowCBNoteURLScheme: false // Prevent infinite loop
                )
                
            } else {
                // Else open URL normally
                // Show temporary screen curtain
                showTmpCurtain = true
                // Open URL
                UIApplication.shared.open(url)
            }
        }
    }
}

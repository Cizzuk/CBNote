//
//  MainViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import Combine
import LockedCameraCapture
import SwiftUI
import Translation
import UniformTypeIdentifiers

extension Notification.Name {
    static let noteListRefreshAttempt = Notification.Name("noteListRefreshAttempt")
}

class MainViewModel: ObservableObject {
    @Published var dummyCamera: (nonce: UUID, view: DummyCameraView)? = nil
    @Published var showDummyCurtain: Bool = false
    
    @Published var pinnedFiles: [URL] = []
    @Published var unpinnedFiles: [URL] = []
    
    @Published var documentDir: DocumentDir = .onDevice
    @Published var sortKey: SortKey = .name
    @Published var sortDirection: SortDirection = .descending
    
    @Published var searchQuery = ""
    @Published var newFileURLToScroll: URL?
    
    @Published var showPasteError = false
    @Published var showCamera = false
    @Published var showSettings = false
    
    @Published var renamingURL: URL?
    @Published var newName = ""
    @Published var isRenaming = false
    
    @Published var showTranslation = false
    @Published var translationText = ""
    
    let noteManager = NoteManager()
    
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
                UserDefaults.standard.set(dir.rawValue, forKey: "documentDir")
            }
            .store(in: &cancellables)
        
        if !documentDir.isAvailable {
            noteManager.setDocumentDir(type: .defaultDir)
        }
        
        noteManager.$sortKey
            .sink { [weak self] key in
                self?.sortKey = key
                UserDefaults.standard.set(key.rawValue, forKey: "sortKey")
            }
            .store(in: &cancellables)
        
        noteManager.$sortDirection
            .sink { [weak self] direction in
                self?.sortDirection = direction
                UserDefaults.standard.set(direction.rawValue, forKey: "sortDirection")
            }
            .store(in: &cancellables)
    }
    
    private func filterFiles(_ files: [URL], query: String) -> [URL] {
        var filteredFiles = files
        
        // Hidden file filter
        let showHiddenFiles = UserDefaults.standard.bool(forKey: "showHiddenFiles")
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
        case .inactive:
            showDummyCurtain = false
        case .background:
            dummyCamera = nil
        @unknown default:
            break
        }
    }
    
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
    
    func createNewNote() {
        guard let newNoteURL = noteManager.createNewNote() else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        newFileURLToScroll = newNoteURL
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func addAndPaste(suppressError: Bool = false) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let currentChangeCount = UIPasteboard.general.changeCount
            if suppressError && currentChangeCount == lastPasteboardChangeCount {
                return
            }
            
            var lastHandled: URL?
            let pasteboard = UIPasteboard.general
            
            for (index, item) in pasteboard.items.enumerated() {
                let indexSet = IndexSet(integer: index)
                func getData(for type: String) -> Data? {
                    pasteboard.data(forPasteboardType: type, inItemSet: indexSet)?.first
                }
                
                // 1. Text or URL -> .txt
                var textContent: String?
                let textTypes = [
                    UTType.plainText.identifier,
                    UTType.utf8PlainText.identifier,
                    UTType.text.identifier,
                    UTType.rtf.identifier,
                ]
                
                if let matchedType = textTypes.first(where: { item.keys.contains($0) }),
                   let data = getData(for: matchedType) {
                    textContent = String(data: data, encoding: .utf8)
                    
                } else if item.keys.contains(UTType.url.identifier),
                          let data = getData(for: UTType.url.identifier) {
                    // This URL is maybe bplist, so need to convert to string
                    // Parse to [Any]
                    if let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [Any] {
                        // Find URL
                        for entry in dict {
                            // Try parse as String
                            if let urlString = entry as? String,
                               // Try convert to URL
                               let url = URL(string: urlString) {
                                // Use absoluteString as text content
                                textContent = url.absoluteString
                                break
                            }
                        }
                    }
                }
                
                if let text = textContent {
                    guard let destURL = noteManager.createFileURL(fileExtension: "txt") else { continue }
                    try? text.write(to: destURL, atomically: true, encoding: .utf8)
                    lastHandled = destURL
                    continue
                }
                
                // 2. File URL
                if item.keys.contains(UTType.fileURL.identifier),
                   let data = getData(for: UTType.fileURL.identifier),
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    
                    guard let destURL = noteManager.createFileURL(fileExtension: url.pathExtension) else { continue }
                    if let fileData = try? Data(contentsOf: url) {
                        try? fileData.write(to: destURL)
                        lastHandled = destURL
                        continue
                    }
                }
                
                // 3. Generic Data (Fallback) (No extension)
                for typeIdentifier in item.keys.sorted() {
                    guard let type = UTType(typeIdentifier),
                          let data = getData(for: typeIdentifier) else { continue }
                    
                    let ext = type.preferredFilenameExtension ?? ""
                    guard let destURL = noteManager.createFileURL(fileExtension: ext) else { continue }
                    try? data.write(to: destURL)
                    lastHandled = destURL
                    break
                }
            }
            
            if let handledURL = lastHandled {
                lastPasteboardChangeCount = currentChangeCount
                DispatchQueue.main.async {
                    self.newFileURLToScroll = handledURL
                }
                loadFiles()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else if !suppressError {
                DispatchQueue.main.async {
                    self.showPasteError = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
    
    func checkAutoPaste() {
        if UserDefaults.standard.bool(forKey: "autoPasteWhenOpening") {
            addAndPaste(suppressError: true)
        }
    }
    
    func copyFile(at url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if FileTypes.isEditableText(url) {
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    UIPasteboard.general.string = text
                }
            } else if FileTypes.isPreviewableImage(url) {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    UIPasteboard.general.image = image
                }
            } else {
                if let fileData = try? Data(contentsOf: url) {
                    UIPasteboard.general.setData(fileData, forPasteboardType: "public.data")
                }
            }
            lastPasteboardChangeCount = UIPasteboard.general.changeCount
        }
    }
    
    func isFilePinned(_ url: URL) -> Bool {
        noteManager.isPinned(url)
    }
    
    func pinUnpinFile(at url: URL) {
        noteManager.togglePin(for: url)
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
        
        // Otherwise, search in Safari
        if let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let searchURL = URL(string: "x-web-search://?\(encodedContent)") {
            UIApplication.shared.open(searchURL)
        }
    }
    
    // Handler for camera capture
    func saveCapturedImage(data: Data, suppress: Bool = false) {
        guard let newImageURL = noteManager.saveCapturedImage(data: data) else {
            if !suppress {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            return
        }
        
        if !suppress {
            DispatchQueue.main.async {
                self.newFileURLToScroll = newImageURL
            }
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
    func handleOpenURL(url: URL, fromCameraControl: Bool = false) {
        switch url.host {
        case "magicaction":
            switch url.pathComponents.dropFirst().first {
            case "home":
                CBNoteApp.backToHomeScreen()
            case "kill":
                CBNoteApp.exitApp()
            default:
                openApp(with: .openAppOnly, fromCameraControl: fromCameraControl)
            }
        case "open":
            var action: OpenAppOption = .openAppOnly

            switch url.pathComponents.dropFirst().first {
            case "camera":
                action = .launchCamera
            case "paste":
                action = .pasteFromClipboard
            case "newnote":
                action = .addNewNote
            default:
                break
            }
            
            openApp(with: action, fromCameraControl: fromCameraControl)
        default:
            openApp(with: .openAppOnly, fromCameraControl: fromCameraControl)
        }
    }
    
    // Handler for launch from camera control
    func handleCameraControlAction() {
        let actionString = UserDefaults.standard.string(forKey: "cameraControlAction")
        let action = OpenAppOption(rawValue: actionString ?? "") ?? .launchCamera
        
        openApp(with: action, fromCameraControl: true)
    }
    
    // Launch a dummy camera to avoid being killed by the system.
    func openDummyCamera() {
        // Create new DummyCamera
        // Update nonce to disable old kill tasks
        let newNonce = UUID()
        dummyCamera = (newNonce, DummyCameraView())
        
        // Kill the dummy camera after 2s.
        // In the test, system killed the app when it was below 0.8 - 1s.
        // For safety, the dummy will be killed in 2s.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            // Check if nonce is not updated
            if let currentNonce = dummyCamera?.nonce, currentNonce == newNonce {
                dummyCamera = nil
            }
        }
    }
    
    func openApp(with action: OpenAppOption, fromCameraControl: Bool = false) {
        // Open Dummy Camera if needed
        if action.shouldOpenDummyCamera && fromCameraControl && UIApplication.shared.applicationState != .active {
            openDummyCamera()
        }
        
        switch action {
        case .launchCamera:
            showSettings = false
            showCamera = true
        case .pasteFromClipboard:
            showSettings = false
            showCamera = false
            addAndPaste()
        case .addNewNote:
            showSettings = false
            showCamera = false
            createNewNote()
        case .openAppOnly:
            showSettings = false
            showCamera = false
        case .openURL:
            if let urlString = UserDefaults.standard.string(forKey: "cameraControlActionOpenURL"),
               let url = URL(string: urlString) {
                // Handle CBNote URL scheme
                if url.scheme == "cbnote" || url.scheme == "net.cizzuk.cbnote" {
                    handleOpenURL(url: url, fromCameraControl: fromCameraControl)
                    return
                }
                
                // Else open URL normally
                // Show dummy curtain without animation
                var transaction = Transaction(animation: .none)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    showSettings = false
                    showCamera = false
                    showDummyCurtain = true
                }
                // Open URL
                UIApplication.shared.open(url)
            } else {
                CBNoteApp.backToHomeScreen()
            }
        }
    }
}

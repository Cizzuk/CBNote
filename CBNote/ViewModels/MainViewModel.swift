//
//  MainViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import Combine
import LockedCameraCapture
import SwiftUI
import UniformTypeIdentifiers

class MainViewModel: ObservableObject {
    @Published var pinnedFiles: [URL] = []
    @Published var unpinnedFiles: [URL] = []
    
    @Published var searchQuery = ""
    @Published var newFileURLToScroll: URL?
    
    @Published var showPasteError = false
    @Published var showDummyCamera = false
    @Published var showCamera = false
    @Published var showSettings = false
    
    @Published var renamingURL: URL?
    @Published var newName = ""
    @Published var isRenaming = false
    
    @Published var documentDir: DocumentDir = .onDevice
    @Published var sortKey: SortKey = .name
    @Published var sortDirection: SortDirection = .descending
    
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
        guard !query.isEmpty else { return files }
        
        return files.filter { url in
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

    func loadFiles() {
        noteManager.loadFiles()
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
                          let data = getData(for: UTType.url.identifier),
                          let url = URL(dataRepresentation: data, relativeTo: nil) {
                    textContent = url.absoluteString
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
                newFileURLToScroll = handledURL
                loadFiles()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else if !suppressError {
                showPasteError = true
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
    
    func deleteFile(at url: URL) {
        noteManager.deleteFile(at: url)
    }
    
    func renameFile() {
        guard let url = renamingURL else { return }
        noteManager.renameFile(at: url, newName: newName)
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
    
    func startRenaming(url: URL) {
        renamingURL = url
        newName = url.lastPathComponent
        isRenaming = true
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
    
    // Handler for launch from camera control
    func handleCameraControlAction() {
        let actionString = UserDefaults.standard.string(forKey: "cameraControlAction")
        let action = OpenAppOption(rawValue: actionString ?? "") ?? .launchCamera
        
        openApp(with: action)
        
        // Launch a dummy camera to avoid being killed by the system.
        if action != .launchCamera && UIApplication.shared.applicationState != .active {
            showDummyCamera = true
            
            // Kill the dummy camera after 2s.
            // In the test, system killed the app when it was below 0.8 - 1s.
            // For safety, the dummy will be killed in 2s.
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
                self.showDummyCamera = false
            }
        }
    }
    
    func openApp(with action: OpenAppOption) {
        showSettings = false
        showDummyCamera = false
        switch action {
        case .launchCamera:
            showCamera = true
        case .pasteFromClipboard:
            showCamera = false
            addAndPaste()
        case .addNewNote:
            showCamera = false
            createNewNote()
        case .openAppOnly:
            showCamera = false
        }
    }
}

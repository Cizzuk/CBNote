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
    @Published var files: [URL] = []
    @Published var pinnedFiles: [URL] = []
    @Published var showPasteError = false
    @Published var showDummyCamera = false
    @Published var showCamera_sheet = false
    @Published var showCamera_popover = false
    @Published var showSettings_sheet = false
    @Published var showSettings_popover = false
    
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
        noteManager.$files
            .assign(to: \.files, on: self)
            .store(in: &cancellables)
            
        noteManager.$pinnedFiles
            .assign(to: \.pinnedFiles, on: self)
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
    
    func showCamera(_ show: Bool) {
        let device = UIDevice.current.userInterfaceIdiom
        if device == .phone {
            showCamera_popover = show
        } else {
            showCamera_sheet = show
        }
    }
    
    func showSettings(_ show: Bool) {
        let device = UIDevice.current.userInterfaceIdiom
        if device == .phone {
            showSettings_popover = show
        } else {
            showSettings_sheet = show
        }
    }

    func createNewNote() {
        noteManager.createNewNote()
    }
    
    func addAndPaste(suppressError: Bool = false) async {
        let currentChangeCount = UIPasteboard.general.changeCount
        if suppressError && currentChangeCount == lastPasteboardChangeCount {
            return
        }
        
        var handled = false
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
                handled = true
                continue
            }
            
            // 2. File URL
            if item.keys.contains(UTType.fileURL.identifier),
               let data = getData(for: UTType.fileURL.identifier),
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                
                guard let destURL = noteManager.createFileURL(fileExtension: url.pathExtension) else { continue }
                if let fileData = try? Data(contentsOf: url) {
                    try? fileData.write(to: destURL)
                    handled = true
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
                handled = true
                break
            }
        }
        
        if handled {
            lastPasteboardChangeCount = currentChangeCount
            loadFiles()
        } else if !suppressError {
            showPasteError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func checkAutoPaste() {
        if UserDefaults.standard.bool(forKey: "autoPasteWhenOpening") {
            Task { await addAndPaste(suppressError: true) }
        }
    }

    func copyFile(at url: URL) {
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
    
    func deleteFile(at url: URL) {
        noteManager.deleteFile(at: url)
    }
    
    // Handler for swipe/context menu delete action
    func deleteFile(offsets: IndexSet) {
        offsets.map { files[$0] }.forEach {
            noteManager.deleteFile(at: $0)
        }
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
    func saveCapturedImage(data: Data) {
        noteManager.saveCapturedImage(data: data)
    }
    
    // Handler for locked camera captures
    func checkLockedCameraCaptures() {
        #if !targetEnvironment(macCatalyst)
        Task {
            let urls = LockedCameraCaptureManager.shared.sessionContentURLs
            for url in urls {
                do {
                    let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    for fileURL in fileURLs {
                        if let data = try? Data(contentsOf: fileURL) {
                            await MainActor.run {
                                saveCapturedImage(data: data)
                            }
                        }
                    }
                    try await LockedCameraCaptureManager.shared.invalidateSessionContent(at: url)
                } catch {
                    print("Error processing locked camera capture: \(error)")
                }
            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showDummyCamera = false
            }
        }
    }
    
    func openApp(with action: OpenAppOption) {
        showSettings(false)
        showDummyCamera = false
        switch action {
        case .launchCamera:
            showCamera(true)
        case .pasteFromClipboard:
            showCamera(false)
            Task { await addAndPaste() }
        case .addNewNote:
            showCamera(false)
            createNewNote()
        case .openAppOnly:
            showCamera(false)
        }
    }
}

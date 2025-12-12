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
    @Published var showPasteError = false
    @Published var showCamera = false
    @Published var showDummyCamera = false
    @Published var showSettings = false
    
    @Published var renamingURL: URL?
    @Published var newName = ""
    @Published var isRenaming = false
    
    @Published var currentSortKey: SortKey = SortKey(rawValue: UserDefaults.standard.string(forKey: "sortKey") ?? "") ?? .name
    @Published var currentSortDirection: SortDirection = SortDirection(rawValue: UserDefaults.standard.string(forKey: "sortDirection") ?? "") ?? .descending
    
    private var lastPasteboardChangeCount: Int = -1
    private var cancellables = Set<AnyCancellable>()
    
    @Published var pinnedFiles: [URL] = {
        let savedStrings = UserDefaults.standard.array(forKey: "pinnedFiles") as? [String] ?? []
        let documentsURL = NoteManager.shared.getDocumentsDirectory()
        return savedStrings.map { documentsURL.appendingPathComponent($0) }
    }() {
        didSet {
            let filenames = pinnedFiles.map { $0.lastPathComponent }
            print("Saving pinned files: \(filenames)")
            UserDefaults.standard.set(filenames, forKey: "pinnedFiles")
        }
    }

    init() {
        NoteManager.shared.$files
            .assign(to: \.files, on: self)
            .store(in: &cancellables)
            
        pinnedFiles = NoteManager.shared.sortFiles(pinnedFiles)
    }

    func loadFiles() {
        NoteManager.shared.loadFiles()
    }
    
    func toggleSort(key: SortKey) {
        if currentSortKey == key {
            currentSortDirection = currentSortDirection == .descending ? .ascending : .descending
        } else {
            currentSortKey = key
            currentSortDirection = .descending
        }
        
        UserDefaults.standard.set(currentSortKey.rawValue, forKey: "sortKey")
        UserDefaults.standard.set(currentSortDirection.rawValue, forKey: "sortDirection")
        
        loadFiles()
        pinnedFiles = NoteManager.shared.sortFiles(pinnedFiles)
    }

    func addItem() {
        let fileURL = NoteManager.shared.createFileURL(fileExtension: "txt")
        
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            loadFiles()
        } catch {
            print("Error creating file: \(error)")
        }
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
                let destURL = NoteManager.shared.createFileURL(fileExtension: "txt")
                try? text.write(to: destURL, atomically: true, encoding: .utf8)
                handled = true
                continue
            }
            
            // 2. File URL
            if item.keys.contains(UTType.fileURL.identifier),
               let data = getData(for: UTType.fileURL.identifier),
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                
                let destURL = NoteManager.shared.createFileURL(fileExtension: url.pathExtension)
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
                let destURL = NoteManager.shared.createFileURL(fileExtension: ext)
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
        NoteManager.shared.deleteFile(at: url)
        pinnedFiles.removeAll { $0 == url }
    }
    
    // Handler for swipe/context menu delete action
    func deleteFile(offsets: IndexSet) {
        offsets.map { files[$0] }.forEach(deleteFile)
        pinnedFiles.removeAll { url in
            offsets.contains(files.firstIndex(of: url) ?? -1)
        }
    }
    
    func renameFile() {
        guard let url = renamingURL else { return }
        NoteManager.shared.renameFile(at: url, newName: newName)
    }
    
    func isFilePinned(_ url: URL) -> Bool {
        let filename = url.lastPathComponent
        return pinnedFiles.contains(where: { $0.lastPathComponent == filename })
    }
    
    func pinUnpinFile(at url: URL) {
        if isFilePinned(url) {
            pinnedFiles.removeAll { $0 == url }
        } else {
            pinnedFiles.append(url)
        }
    }
    
    func isValidFileName(_ name: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.rangeOfCharacter(from: invalidCharacters) == nil && !name.isEmpty
    }
    
    func startRenaming(url: URL) {
        renamingURL = url
        newName = url.lastPathComponent
        isRenaming = true
    }
    
    // Handler for camera capture
    func saveImage(data: Data) {
        let fileURL = NoteManager.shared.createFileURL(fileExtension: "jpeg")
        
        do {
            try data.write(to: fileURL)
            loadFiles()
        } catch {
            print("Error saving camera image: \(error)")
        }
    }
    
    // Handler for locked camera captures
    func checkLockedCameraCaptures() {
        Task {
            let urls = LockedCameraCaptureManager.shared.sessionContentURLs
            for url in urls {
                do {
                    let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    for fileURL in fileURLs {
                        if let data = try? Data(contentsOf: fileURL) {
                            await MainActor.run {
                                saveImage(data: data)
                            }
                        }
                    }
                    try await LockedCameraCaptureManager.shared.invalidateSessionContent(at: url)
                } catch {
                    print("Error processing locked camera capture: \(error)")
                }
            }
        }
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
        showSettings = false
        showDummyCamera = false
        switch action {
        case .launchCamera:
            showCamera = true
        case .pasteFromClipboard:
            showCamera = false
            Task { await addAndPaste() }
        case .addNewNote:
            showCamera = false
            addItem()
        case .openAppOnly:
            showCamera = false
        }
    }
}

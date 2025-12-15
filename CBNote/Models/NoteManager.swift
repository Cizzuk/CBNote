//
//  NoteManager.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/07.
//

import Combine
import Foundation

class NoteManager: ObservableObject {
    
    @Published var files: [URL] = []
    @Published var pinnedFiles: [URL] = []
    @Published var unpinnedFiles: [URL] = []
    
    @Published var documentDir: DocumentDir {
        didSet {
            loadPinnedFiles()
            loadFiles()
        }
    }
    
    @Published var sortKey: SortKey {
        didSet {
            loadFiles()
        }
    }
    
    @Published var sortDirection: SortDirection {
        didSet {
            loadFiles()
        }
    }
    
    init() {
        // Load UserDefaults
        self.documentDir = DocumentDir(rawValue: UserDefaults.standard.string(forKey: "documentDir") ?? "") ?? .defaultDir
        self.sortKey = SortKey(rawValue: UserDefaults.standard.string(forKey: "sortKey") ?? "") ?? .name
        self.sortDirection = SortDirection(rawValue: UserDefaults.standard.string(forKey: "sortDirection") ?? "") ?? .descending
        
        loadPinnedFiles()
        loadFiles()
    }
    
    func loadFiles() {
        guard let documentsURL = documentDir.directory,
              let fileURLs = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey])
        else {
            files = []
            pinnedFiles = []
            unpinnedFiles = []
            print("Error loading files from directory: \(documentDir.rawValue)")
            return
        }
        
        // Sort & Filter
        files = sortFiles(fileURLs)
        pinnedFiles = files.filter { self.isPinned($0) }
        unpinnedFiles = files.filter { !self.isPinned($0) }
    }
    
    func setDocumentDir(type: DocumentDir) {
        documentDir = type
    }
    
    func sortFiles(_ urls: [URL]) -> [URL] {
        return urls.sorted { url1, url2 in
            switch sortKey {
            case .name:
                let name1 = url1.lastPathComponent.lowercased()
                let name2 = url2.lastPathComponent.lowercased()
                return sortDirection == .descending ? name1 > name2 : name1 < name2
            case .date:
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return sortDirection == .descending ? date1 > date2 : date1 < date2
            }
        }
    }
    
    func setSort(key: SortKey, direction: SortDirection) {
        sortKey = key
        sortDirection = direction
    }
    
    func createFileURL(fileExtension: String, suffix: String = "") -> URL? {
        guard let documentsURL = documentDir.directory else { return nil }
        
        let dateFormatter = DateFormatter()
        let dateFormat = UserDefaults.standard.string(forKey: "nameFormat") ?? "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.dateFormat = dateFormat
        let baseName = dateFormatter.string(from: Date()) + suffix
        let extensionPart = fileExtension.isEmpty ? "" : ".\(fileExtension)"
        
        // Ensure unique filename
        var counter = 0
        var fileURL: URL
        repeat {
            counter += 1
            let counterNumber = counter > 1 ? "-\(counter)" : ""

            let fileName = "\(baseName)\(counterNumber)\(extensionPart)"
            fileURL = documentsURL.appendingPathComponent(fileName)
        } while FileManager.default.fileExists(atPath: fileURL.path)
                    
        return fileURL
    }
    
    func createNewNote() -> URL? {
        guard let fileURL = createFileURL(fileExtension: "txt") else { return nil }
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            loadFiles()
            return fileURL
        } catch {
            print("Error creating file: \(error)")
        }
        return nil
    }
    
    func saveCapturedImage(data: Data) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let fileURL = self.createFileURL(fileExtension: "jpeg") else { return }
            
            do { try data.write(to: fileURL) }
            catch { print("Error saving captured image: \(error)") }
            
            self.loadFiles()
        }
    }
    
    func deleteFile(at url: URL) {
        DispatchQueue.global(qos: .utility).async {
            do { try FileManager.default.removeItem(at: url) }
            catch { print("Error deleting file: \(error)") }
                
            if self.isPinned(url) {
                self.togglePin(for: url)
            }
            
            self.loadFiles()
        }
    }
    
    func renameFile(at url: URL, newName: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let folder = url.deletingLastPathComponent()
            let newURL = folder.appendingPathComponent(newName)
            let wasPinned = self.isPinned(url)
            
            do {
                try FileManager.default.moveItem(at: url, to: newURL)
                
                // Re pin
                if wasPinned {
                    self.pinnedFiles.removeAll { $0.path == url.path }
                    self.pinnedFiles.append(newURL)
                    self.savePinnedFiles()
                }
            } catch { print("Error renaming file: \(error)") }
            
            self.loadFiles()
        }
    }
    
    func isValidFileName(_ name: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.rangeOfCharacter(from: invalidCharacters) == nil && !name.isEmpty
    }
    
    // MARK: - Pinned Files
    
    private func loadPinnedFiles() {
        guard let documentsURL = documentDir.directory else {
            pinnedFiles = []
            return
        }
        
        let savedStrings = UserDefaults.standard.array(forKey: documentDir.pinnedKey) as? [String] ?? []
        let loadedFiles = savedStrings.map { documentsURL.appendingPathComponent($0) }
        pinnedFiles = sortFiles(loadedFiles)
    }
    
    func isPinned(_ url: URL) -> Bool {
        let filename = url.lastPathComponent
        return pinnedFiles.contains(where: { $0.lastPathComponent == filename })
    }
    
    func togglePin(for url: URL) {
        if isPinned(url) {
            pinnedFiles.removeAll { $0.lastPathComponent == url.lastPathComponent }
        } else {
            pinnedFiles.append(url)
        }
        
        // Re sort and update
        pinnedFiles = sortFiles(pinnedFiles)
        unpinnedFiles = files.filter { !isPinned($0) }
        
        savePinnedFiles()
    }
    
    private func savePinnedFiles() {
        DispatchQueue.global(qos: .background).async {
            let filenames = self.pinnedFiles.map { $0.lastPathComponent }
            UserDefaults.standard.set(filenames, forKey: self.documentDir.pinnedKey)
        }
    }
}

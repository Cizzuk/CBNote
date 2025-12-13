//
//  NoteManager.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/07.
//

import Combine
import Foundation

enum DocumentDir: String, CaseIterable {
    case onDevice
    case iCloud
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .onDevice:
            return "On Device"
        case .iCloud:
            return "iCloud"
        }
    }
    
    var directory: URL? {
        switch self {
        case .onDevice:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .iCloud:
            if self.isAvailable,
               let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
                return url.appendingPathComponent("Documents")
            } else {
                print("iCloud container not available")
                return nil
            }
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .onDevice:
            return true
        case .iCloud:
            return FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
        }
    }
    
    static var availableDirs: [DocumentDir] {
        return DocumentDir.allCases.filter { $0.isAvailable }
    }
    
    static var defaultDir: DocumentDir {
        if DocumentDir.iCloud.isAvailable {
            return .iCloud
        } else {
            return .onDevice
        }
    }

    // For UserDefaults
    var pinnedKey: String {
        switch self {
        case .onDevice:
            return "pinnedFiles_OnDevice"
        case .iCloud:
            return "pinnedFiles_iCloud"
        }
    }
}


enum SortKey: String, CaseIterable {
    case name // Default
    case date // Modification Date
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .name:
            return "Name"
        case .date:
            return "Date"
        }
    }
}

enum SortDirection: String {
    case descending // Default
    case ascending
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .descending:
            return "Descending"
        case .ascending:
            return "Ascending"
        }
    }
}

class NoteManager: ObservableObject {
    
    @Published var files: [URL] = []
    @Published var pinnedFiles: [URL] = []
    
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
        do {
            guard let documentsURL = documentDir.directory else {
                files = []
                return
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey])
            
            // Sort
            files = sortFiles(fileURLs)
            pinnedFiles = sortFiles(pinnedFiles)
        } catch {
            print("Error loading files: \(error)")
            files = []
        }
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
    
    func createNewNote() {
        guard let fileURL = createFileURL(fileExtension: "txt") else { return }
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            loadFiles()
        } catch {
            print("Error creating file: \(error)")
        }
    }
    
    func saveCapturedImage(data: Data) {
        guard let fileURL = createFileURL(fileExtension: "jpeg") else { return }
        do {
            try data.write(to: fileURL)
            loadFiles()
        } catch {
            print("Error saving camera image: \(error)")
        }
    }
    
    func deleteFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            if isPinned(url) {
                togglePin(for: url)
            }
            loadFiles()
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    func renameFile(at url: URL, newName: String) {
        let folder = url.deletingLastPathComponent()
        let newURL = folder.appendingPathComponent(newName)
        
        let wasPinned = isPinned(url)
        
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            
            // Re pin
            if wasPinned {
                pinnedFiles.removeAll { $0.path == url.path }
                pinnedFiles.append(newURL)
                savePinnedFiles()
            }
            
            loadFiles()
        } catch {
            print("Error renaming file: \(error)")
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
    
    private func savePinnedFiles() {
        let filenames = pinnedFiles.map { $0.lastPathComponent }
        UserDefaults.standard.set(filenames, forKey: documentDir.pinnedKey)
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
        pinnedFiles = sortFiles(pinnedFiles)
        savePinnedFiles()
    }
}

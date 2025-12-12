//
//  NoteManager.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/07.
//

import Combine
import Foundation

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
    static let shared = NoteManager()
    
    @Published var files: [URL] = []
    @Published var pinnedFiles: [URL] = []
    
    @Published var sortKey: SortKey = SortKey(rawValue: UserDefaults.standard.string(forKey: "sortKey") ?? "") ?? .name {
        didSet {
            UserDefaults.standard.set(sortKey.rawValue, forKey: "sortKey")
            loadFiles()
        }
    }
    
    @Published var sortDirection: SortDirection = SortDirection(rawValue: UserDefaults.standard.string(forKey: "sortDirection") ?? "") ?? .descending {
        didSet {
            UserDefaults.standard.set(sortDirection.rawValue, forKey: "sortDirection")
            loadFiles()
        }
    }
    
    private init() {
        loadPinnedFiles()
        loadFiles()
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func loadFiles() {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey])
            
            // Sort
            files = sortFiles(fileURLs)
            pinnedFiles = sortFiles(pinnedFiles)
        } catch {
            print("Error loading files: \(error)")
            files = []
        }
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
    
    func toggleSort(key: SortKey) {
        if sortKey == key {
            sortDirection = sortDirection == .descending ? .ascending : .descending
        } else {
            sortKey = key
            sortDirection = .descending
        }
    }
    
    func createFileURL(fileExtension: String, suffix: String = "") -> URL {
        let dateFormatter = DateFormatter()
        let dateFormat = UserDefaults.standard.string(forKey: "nameFormat") ?? "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.dateFormat = dateFormat
        let baseName = dateFormatter.string(from: Date()) + suffix
        
        let documentsURL = getDocumentsDirectory()
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
        let fileURL = createFileURL(fileExtension: "txt")
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            loadFiles()
        } catch {
            print("Error creating file: \(error)")
        }
    }
    
    func saveCapturedImage(data: Data) {
        let fileURL = createFileURL(fileExtension: "jpeg")
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
        let savedStrings = UserDefaults.standard.array(forKey: "pinnedFiles") as? [String] ?? []
        let documentsURL = getDocumentsDirectory()
        let loadedFiles = savedStrings.map { documentsURL.appendingPathComponent($0) }
        pinnedFiles = sortFiles(loadedFiles)
    }
    
    private func savePinnedFiles() {
        let filenames = pinnedFiles.map { $0.lastPathComponent }
        print("Saving pinned files: \(filenames)")
        UserDefaults.standard.set(filenames, forKey: "pinnedFiles")
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

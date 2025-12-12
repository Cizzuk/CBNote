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
    
    private init() {
        loadFiles()
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func loadFiles() {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey])
            
            files = sortFiles(fileURLs)
        } catch {
            print("Error loading files: \(error)")
            files = []
        }
    }
    
    func sortFiles(_ urls: [URL]) -> [URL] {
        let key = SortKey(rawValue: UserDefaults.standard.string(forKey: "sortKey") ?? "") ?? .name
        let direction = SortDirection(rawValue: UserDefaults.standard.string(forKey: "sortDirection") ?? "") ?? .ascending
        
        return urls.sorted { url1, url2 in
            switch key {
            case .name:
                return direction == .descending ? url1.lastPathComponent.lowercased() > url2.lastPathComponent.lowercased() : url1.lastPathComponent.lowercased() < url2.lastPathComponent.lowercased()
            case .date:
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return direction == .descending ? date1 > date2 : date1 < date2
            }
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
    
    func deleteFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            loadFiles()
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    func renameFile(at url: URL, newName: String) {
        let folder = url.deletingLastPathComponent()
        let newURL = folder.appendingPathComponent(newName)
        
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            loadFiles()
        } catch {
            print("Error renaming file: \(error)")
        }
    }
}

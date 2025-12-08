//
//  NoteManager.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/07.
//

import Foundation
import Combine

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
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            files = fileURLs.sorted { url1, url2 in
                url1.lastPathComponent > url2.lastPathComponent
            }
        } catch {
            print("Error loading files: \(error)")
            files = []
        }
    }
    
    func createFileURL(fileExtension: String, suffix: String = "") -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let baseName = dateFormatter.string(from: Date()) + suffix
        
        let documentsURL = getDocumentsDirectory()
        
        var counter = 1
        let extensionPart = fileExtension.isEmpty ? "" : ".\(fileExtension)"
        var fileName = "\(baseName)-\(counter)\(extensionPart)"
        var fileURL = documentsURL.appendingPathComponent(fileName)
        
        // Ensure unique filename
        while FileManager.default.fileExists(atPath: fileURL.path) {
            counter += 1
            fileName = "\(baseName)-\(counter)\(extensionPart)"
            fileURL = documentsURL.appendingPathComponent(fileName)
        }
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

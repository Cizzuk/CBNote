//
//  ClipboardManager.swift
//  CBNote
//
//  Created by Cizzuk on 2026/06/05.
//

import UniformTypeIdentifiers
import UIKit

class ClipboardManager {
    static func copyFile(at url: URL, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
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
            DispatchQueue.main.async { completion() }
        }
    }
    
    enum PasteError: Error {
        case noValidContent
    }
    
    static func newNoteFromClipboard(
        noteManager: NoteManager,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
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
                completion(.success(handledURL))
            } else {
                completion(.failure(PasteError.noValidContent))
            }
        }
    }
}


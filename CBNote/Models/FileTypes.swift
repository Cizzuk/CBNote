//
//  FileTypes.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import UniformTypeIdentifiers

struct FileTypes {
    static func isEditableText(_ url: URL) -> Bool {
        let editableText = ["rtf", "xml", "html", "htm", "tex", "json", "yaml", "yml", "toml"]
        let isEditableText: Bool = editableText.contains(url.pathExtension.lowercased())
        
        if let type = UTType(filenameExtension: url.pathExtension) {
            return (type.conforms(to: .plainText) || isEditableText)
        } else {
            return isEditableText
        }
    }
    
    static func isPreviewableImage(_ url: URL) -> Bool {
        let previewableImage = ["png", "jpg", "jpeg", "heic"]
        return previewableImage.contains(url.pathExtension.lowercased())
    }
    
    static func isCopiableToClipboard(_ url: URL) -> Bool {
        return isEditableText(url) || isPreviewableImage(url)
    }
    
    static func name(for url: URL) -> String {
        if url.hasDirectoryPath {
            return "Folder"
        }
        
        if let type = UTType(filenameExtension: url.pathExtension),
           let description = type.localizedDescription {
            return description
        }
        return "Unknown File Type"
    }
    
    static func systemImage(for url: URL) -> String {
        if url.hasDirectoryPath {
            return "folder"
        }
        
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return "doc"
        }
        
        // Media
        if type.conforms(to: .image) {
            return "photo"
        } else if type.conforms(to: .audio) {
            return "waveform"
        } else if type.conforms(to: .audiovisualContent) {
            return "film"
            
        // Source Code & Script
        } else if type.conforms(to: .swiftSource) {
            return "swift"
        } else if type.conforms(to: .sourceCode) {
            return "curlybraces"
        } else if type.conforms(to: .script) {
            return "curlybraces"
            
        // Data Formats
        } else if type.conforms(to: .xml) {
            return "chevron.left.forwardslash.chevron.right"
        } else if type.conforms(to: .html) {
            return "chevron.left.forwardslash.chevron.right"
        } else if type.conforms(to: .css) {
            return "curlybraces"
        } else if type.conforms(to: .json) {
            return "curlybraces"
            
        // Documents
        } else if type.conforms(to: .spreadsheet) {
            return "tablecells"
        } else if type.conforms(to: .presentation) {
            return "chart.bar.doc.horizontal"
        } else if type.conforms(to: .pdf) {
            return "doc.richtext"
        } else if type.conforms(to: .database) {
            return "server.rack"
        } else if type.conforms(to: .calendarEvent) {
            return "calendar"
        } else if type.conforms(to: .contact) {
            return "person.crop.square.filled.and.at.rectangle"
        } else if type.conforms(to: .emailMessage) {
            return "envelope"
        } else if type.conforms(to: .url) {
            return "link"
        } else if type.conforms(to: .internetLocation) {
            return "link"
            
        // Text
        } else if type.conforms(to: .text) {
            return "doc.text"
        } else if type.conforms(to: .plainText) {
            return "doc.plaintext"
        } else if type.conforms(to: .rtf) {
            return "doc.richtext"
        } else if type.conforms(to: .font) {
            return "textformat"
            
        // Applications
        } else if type.conforms(to: .exe) {
            return "uiwindow.split.2x1"
        } else if url.pathExtension.lowercased() == "ipa" {
            return "app.grid"
        } else if type.conforms(to: .bundle) {
            return "app.shadow"
        } else if type.conforms(to: .applicationBundle) {
            return "app"
        } else if type.conforms(to: .applicationExtension) {
            return "puzzlepiece.extension"
        } else if type.conforms(to: .application) {
            return "app.grid"
        } else if type.conforms(to: .executable) {
            return "apple.terminal"
            
        // Archive
        } else if type.conforms(to: .webArchive) {
            return "safari"
        } else if type.conforms(to: .archive) {
            return "zipper.page"
            
        // Others
        } else if type.conforms(to: .folder) {
            return "folder"
        } else if type.conforms(to: .aliasFile) {
            return "arrowshape.turn.up.left"
        } else if type.conforms(to: .symbolicLink) {
            return "arrowshape.turn.up.left"
        } else {
            return "doc"
        }
    }
}

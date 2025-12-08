//
//  FileTypes.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import Foundation

struct FileTypes {
    static let text = ["txt", "md", "csv", "rtf", "xml", "html", "htm", "log", "tex", "json", "yaml", "yml", "toml"]
    static let image = ["png", "jpg", "jpeg", "heic"]
    
    static func isText(_ url: URL) -> Bool {
        text.contains(url.pathExtension.lowercased())
    }
    
    static func isImage(_ url: URL) -> Bool {
        image.contains(url.pathExtension.lowercased())
    }
}

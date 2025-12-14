//
//  WatchConnectivitySupport.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/14.
//

import Foundation
import UniformTypeIdentifiers

// MARK: - Data Models for Watch

struct WatchFileItem: Identifiable, Codable, Hashable {
    let id: URL
    let name: String
    let systemImage: String
    let preview: String?
    let isPinned: Bool
    
    init(url: URL, preview: String? = nil, isPinned: Bool = false) {
        self.id = url
        self.name = url.lastPathComponent
        self.preview = preview
        self.isPinned = isPinned
        self.systemImage = FileTypes.systemImage(for: url)
    }
}

struct WatchDirectoryInfo: Identifiable, Codable, Hashable {
    let id: String // Raw value of DocumentDir
    let name: String // Localized name
    let systemImage: String
}

// MARK: - Protocol

// Requests sent from Watch to iPhone
enum WatchConnectivityRequest: Codable {
    case getDirectoryList
    case getFileList(directory: String)
    case getFileContent(directory: String, fileName: String)
}

// Responses sent from iPhone to Watch
enum WatchConnectivityResponse: Codable {
    case directoryList([WatchDirectoryInfo])
    case fileList(unpinned: [WatchFileItem], pinned: [WatchFileItem])
    case fileContent(WatchFileContent)
    case error(String)
}

// Supported content
enum WatchFileContent: Codable {
    case text(String)
    case image(Data)
    case unsupported
}

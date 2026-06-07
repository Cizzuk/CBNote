//
//  iCloudSupport.swift
//  CBNote
//
//  Created by Cizzuk on 2026/01/03.
//

import Foundation

class iCloudSupport {
    static var isAvailable: Bool {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }
    
    static var directoryURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    static func isiCloudItem(at url: URL) -> Bool {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
            return resourceValues.isUbiquitousItem ?? false
        } catch {
            return false
        }
    }
    
    static func itemDownloadingStatus(at url: URL) -> URLUbiquitousItemDownloadingStatus? {
        if !isiCloudItem(at: url) {
            return .current
        }
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            return resourceValues.ubiquitousItemDownloadingStatus
        } catch {
            return nil
        }
    }

    
    static func isDownloaded(at url: URL) -> Bool? {
        let status = itemDownloadingStatus(at: url)
        
        switch status {
        case .current, .downloaded:
            return true
        case .notDownloaded:
            return false
        default:
            return nil
        }
    }
}

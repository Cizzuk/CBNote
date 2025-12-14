//
//  WatchConnectivityManager.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/07.
//

import Combine
import UIKit
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activated: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        // Parse request
        guard let data = message["payload"] as? Data,
              let request = try? JSONDecoder().decode(WatchConnectivityRequest.self, from: data) else {
            return
        }
        
        let noteManager = NoteManager()
        
        switch request {
        case .getDirectoryList:
            let dirs = DocumentDir.availableDirs.map { dir -> WatchDirectoryInfo in
                // Resolve localized string
                let name = String(localized: dir.localizedName)
                let systemImage = dir.systemImage
                return WatchDirectoryInfo(id: dir.rawValue, name: name, systemImage: systemImage)
            }
            sendResponse(.directoryList(dirs), replyHandler: replyHandler)
            
        case .getFileList(let directoryRawValue):
            // Prepare NoteManager
            guard let dir = DocumentDir(rawValue: directoryRawValue) else {
                sendResponse(.error("Invalid directory"), replyHandler: replyHandler)
                return
            }
            noteManager.setDocumentDir(type: dir)
            noteManager.loadFiles()
            
            // Map files to WatchFileItem
            let mapFile: (URL) -> WatchFileItem = { url in
                var preview: String?
                if FileTypes.isEditableText(url) {
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        if !content.isEmpty {
                            preview = content.components(separatedBy: .newlines).first
                        }
                    }
                }
                return WatchFileItem(url: url, preview: preview, isPinned: noteManager.isPinned(url))
            }
            
            let pinned = noteManager.pinnedFiles.map(mapFile)
            let unpinned = noteManager.unpinnedFiles.map(mapFile)
            
            sendResponse(.fileList(pinned: pinned, unpinned: unpinned), replyHandler: replyHandler)
            
        case .getFileContent(let directoryRawValue, let fileName):
            // Resolve directory
            guard let dir = DocumentDir(rawValue: directoryRawValue), let documentsURL = dir.directory else {
                sendResponse(.error("Invalid directory"), replyHandler: replyHandler)
                return
            }
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            if FileTypes.isPreviewableImage(fileURL) {
                // Compress to lower quality JPEG
                if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                    let maxDimension: CGFloat = 300
                    let size = image.size
                    let ratio = min(maxDimension / size.width, maxDimension / size.height)
                    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
                    let renderer = UIGraphicsImageRenderer(size: newSize)
                    let resizedImage = renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: newSize))
                    }
                    if let jpegData = resizedImage.jpegData(compressionQuality: 0.3) {
                        sendResponse(.fileContent(.image(jpegData)), replyHandler: replyHandler)
                    } else {
                        sendResponse(.error("Could not process image"), replyHandler: replyHandler)
                    }
                } else {
                    sendResponse(.error("Could not load image"), replyHandler: replyHandler)
                }
            } else if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
                sendResponse(.fileContent(.text(text)), replyHandler: replyHandler)
            } else {
                sendResponse(.fileContent(.unsupported), replyHandler: replyHandler)
            }
        }
    }
    
    private func sendResponse(_ response: WatchConnectivityResponse, replyHandler: @escaping ([String : Any]) -> Void) {
        if let data = try? JSONEncoder().encode(response) {
            replyHandler(["payload": data])
        }
    }
}

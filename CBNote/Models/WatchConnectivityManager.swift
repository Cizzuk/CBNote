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
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let request = message["request"] as? String else { return }
        
        if request == "getFileList" {
            // Get all files info
            
            NoteManager.shared.loadFiles()
            let files = NoteManager.shared.files
            
            let pinnedFiles = files.filter { NoteManager.shared.isPinned($0) }
            let unpinnedFiles = files.filter { !NoteManager.shared.isPinned($0) }
            
            let fileMapper: (URL) -> [String: String] = { url in
                var info = ["name": url.lastPathComponent]
                
                // Add preview for text files
                if FileTypes.isEditableText(url) {
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        // Cut to first line only
                        let firstLine = content.components(separatedBy: .newlines).first ?? ""
                        if !firstLine.isEmpty {
                            info["preview"] = firstLine
                        }
                    }
                }
                return info
            }
            
            replyHandler([
                "unpinnedFiles": unpinnedFiles.map(fileMapper),
                "pinnedFiles": pinnedFiles.map(fileMapper)
            ])
            
        } else if request == "getFileContent", let fileName = message["fileName"] as? String {
            // Get file content
            
            guard let documentsURL = NoteManager.shared.documentDir.directory else {
                replyHandler(["error": "Could not access documents directory"])
                return
            }
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            if FileTypes.isPreviewableImage(fileURL) {
                // Handle image file
                if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                    // Resize to max 300px width/height for Watch
                    let maxDimension: CGFloat = 300
                    let size = image.size
                    let ratio = min(maxDimension / size.width, maxDimension / size.height)
                    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
                    
                    let renderer = UIGraphicsImageRenderer(size: newSize)
                    let resizedImage = renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: newSize))
                    }
                    
                    // Compress to lower quality JPEG
                    if let jpegData = resizedImage.jpegData(compressionQuality: 0.3) {
                         replyHandler(["imageData": jpegData])
                    } else {
                         replyHandler(["error": "Could not process image"])
                    }
                } else {
                    replyHandler(["error": "Could not load file"])
                }
                
            } else if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
                // Handle text file
                replyHandler(["text": text])
                
            } else {
                replyHandler(["error": "Could not load file"])
            }
        }
    }
}

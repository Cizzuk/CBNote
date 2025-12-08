//
//  WatchViewModel.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/07.
//

import Foundation
import WatchConnectivity
import SwiftUI
import Combine

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var files: [FileItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct FileItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let preview: String?
        
        var url: URL {
            URL(fileURLWithPath: name)
        }
        
        var isImage: Bool {
            FileTypes.isImage(url)
        }
        
        var isText: Bool {
            FileTypes.isText(url)
        }
    }
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = "Connection error: \(error.localizedDescription)"
            }
        } else {
            loadFiles()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            loadFiles()
        }
    }
    
    func loadFiles() {
        guard WCSession.default.activationState == .activated else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Send request to iPhone
        WCSession.default.sendMessage(["request": "getFileList"], replyHandler: { message in
            if let filesData = message["files"] as? [[String: String]] {
                // Parse file items
                let items = filesData.compactMap { dict -> FileItem? in
                    guard let name = dict["name"] else { return nil }
                    let preview = dict["preview"]
                    return FileItem(name: name, preview: preview)
                }
                DispatchQueue.main.async {
                    self.files = items
                    self.isLoading = false
                }
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error loading files: \(error.localizedDescription)"
            }
        })
    }
    
    func getFileContent(fileName: String, completion: @escaping (Any?) -> Void) {
        // Send request to iPhone
        WCSession.default.sendMessage(["request": "getFileContent", "fileName": fileName], replyHandler: { message in
            // Parse content
            if let text = message["text"] as? String {
                completion(text)
            } else if let imageData = message["imageData"] as? Data, let image = UIImage(data: imageData) {
                completion(image)
            } else {
                completion(nil)
            }
        }, errorHandler: { error in
            print("Error fetching content: \(error.localizedDescription)")
            completion(nil)
        })
    }
}

//
//  WatchConnectionModel.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/14.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectionModel: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectionModel()
    
    // iPhone state
    @Published var directories: [WatchDirectoryInfo] = []
    
    // Current directory
    @Published var currentDirectoryId: String?
    @Published var pinnedFiles: [WatchFileItem] = []
    @Published var unpinnedFiles: [WatchFileItem] = []
    
    // Watch state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.setError(error.localizedDescription)
            }
        } else {
            // Initial fetch
            fetchDirectories()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            fetchDirectories()
        }
    }
    
    // MARK: - Requests
    
    func fetchDirectories() {
        isLoading = true
        sendRequest(.getDirectoryList) { response in
            DispatchQueue.main.async {
                self.isLoading = false
                switch response {
                case .directoryList(let dirs):
                    self.directories = dirs
                case .error(let msg):
                    self.setError(msg)
                default:
                    break
                }
            }
        }
    }
    
    func fetchFiles(directoryId: String) {
        isLoading = true
        currentDirectoryId = directoryId
        sendRequest(.getFileList(directory: directoryId)) { response in
            DispatchQueue.main.async {
                self.isLoading = false
                switch response {
                case .fileList(let pinned, let unpinned):
                    self.pinnedFiles = pinned
                    self.unpinnedFiles = unpinned
                case .error(let msg):
                    self.setError(msg)
                default:
                    break
                }
            }
        }
    }
    
    func fetchFileContent(fileName: String, completion: @escaping (WatchFileContent?) -> Void) {
        guard let dirId = currentDirectoryId else { return }
        isLoading = true
        sendRequest(.getFileContent(directory: dirId, fileName: fileName)) { response in
            DispatchQueue.main.async {
                self.isLoading = false
                switch response {
                case .fileContent(let content):
                    completion(content)
                case .error(let msg):
                    self.setError(msg)
                    completion(nil)
                default:
                    completion(nil)
                }
            }
        }
    }
    
    private func sendRequest(_ request: WatchConnectivityRequest, completion: @escaping (WatchConnectivityResponse) -> Void) {
        guard connectabilityCheck() else { return }
        
        guard let data = try? JSONEncoder().encode(request) else { return }
        
        WCSession.default.sendMessage(["payload": data], replyHandler: { reply in
            // Parse reply
            if let data = reply["payload"] as? Data,
               let response = try? JSONDecoder().decode(WatchConnectivityResponse.self, from: data) {
                completion(response)
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.setError(error.localizedDescription)
            }
        })
    }
    
    private func connectabilityCheck() -> Bool {
        guard WCSession.default.isReachable else {
            // Wait a moment to see if it becomes reachable
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if !WCSession.default.isReachable {
                    self.setLocalizedError("Cannot connect to iPhone.")
                }
            }
            return false
        }
        
        guard !WCSession.default.iOSDeviceNeedsUnlockAfterRebootForReachability else {
            if !WCSession.default.iOSDeviceNeedsUnlockAfterRebootForReachability {
                self.setLocalizedError("iPhone needs to be unlocked after reboot.")
            }
            return false
        }
        
        guard WCSession.default.isCompanionAppInstalled else {
            if WCSession.default.isCompanionAppInstalled {
                self.setLocalizedError("Companion app is not installed on iPhone.")
            }
            return false
        }
        
        guard WCSession.default.activationState == .activated else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if WCSession.default.activationState != .activated {
                    self.setLocalizedError("Connection is not activated.")
                }
            }
            return false
        }
        
        return true
    }
    
    private func setError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }
    
    private func setLocalizedError(_ message: LocalizedStringResource) {
        let message = String(localized: message)
        setError(message)
    }
}

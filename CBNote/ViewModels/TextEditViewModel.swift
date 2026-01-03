//
//  TextEditViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/13.
//

import Combine
import SwiftUI

class TextEditViewModel: ObservableObject {
    let url: URL
    @Published var text: String = ""
    @Published var isLoading: Bool = true
    @Published var isFileEditable: Bool = false
    
    init(url: URL) {
        self.url = url
    }
    
    func loadContent() {
        // Check permissions
        if !FileManager.default.isWritableFile(atPath: self.url.path) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        // Load content
        if iCloudSupport().isDownloaded(at: url) ?? false {
            // Already downloaded, load in main thread
            if let content = try? String(contentsOf: self.url, encoding: .utf8) {
                self.text = content
                self.isFileEditable = true
            }
            self.isLoading = false
            
        } else {
            // Not downloaded, load in background thread
            DispatchQueue.global(qos: .userInteractive).async {
                if let content = try? String(contentsOf: self.url, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.text = content
                        self.isFileEditable = true
                    }
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveText() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                // Retry after 1s
                DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1) {
                    do {
                        try self.text.write(to: self.url, atomically: true, encoding: .utf8)
                    } catch {
                        print("Failed to save text to \(self.url): \(error)")
                    }
                }
            }
        }
    }
    
    func textFont() -> Font {
        if FileTypes.shouldMonospaceFont(url) {
            return .system(.body, design: .monospaced)
        } else {
            return .body
        }
    }
}

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
        DispatchQueue.global(qos: .userInitiated).async {
            // Check permissions
            if !FileManager.default.isWritableFile(atPath: self.url.path) {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Read file content
            if let content = try? String(contentsOf: self.url, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.text = content
                    self.isFileEditable = true
                }
            }
            
            // Finish loading
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func saveText() {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving text: \(error)")
        }
    }
}

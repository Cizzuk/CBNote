//
//  FileRowViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import SwiftUI
import Combine

class FileRowViewModel: ObservableObject {
    let url: URL
    @Published var text: String = ""
    
    init(url: URL) {
        self.url = url
    }
    
    func loadContent() {
        if FileTypes.isEditableText(url) {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                text = content
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

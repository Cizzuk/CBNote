//
//  FileRowViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import Combine
import SwiftUI

class FileRowViewModel: ObservableObject {
    let url: URL
    @Published var text: String = ""
    @Published var isLoading: Bool = true
    
    init(url: URL) {
        self.url = url
    }
    
    func loadContent() {
        if FileTypes.isEditableText(url) {
            DispatchQueue.global(qos: .userInitiated).async {
                let content = (try? String(contentsOf: self.url, encoding: .utf8)) ?? ""
                DispatchQueue.main.async {
                    self.text = content
                    self.isLoading = false
                }
            }
        } else {
            isLoading = false
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

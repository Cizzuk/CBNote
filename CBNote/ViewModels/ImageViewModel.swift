//
//  ImageViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import Combine
import SwiftUI

class ImageViewModel: ObservableObject {
    let url: URL
    @Published var uiImage: UIImage?
    @Published var isLoading: Bool = true
    
    init(url: URL) {
        self.url = url
    }
    
    func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Read file content
            if let data = try? Data(contentsOf: self.url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
            
            // Finish loading
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

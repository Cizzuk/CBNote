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
        if iCloudSupport().isDownloaded(at: url) ?? false {
            // Already downloaded, load in main thread
            if let data = try? Data(contentsOf: self.url),
               let image = UIImage(data: data) {
                self.uiImage = image
            }
            self.isLoading = false
            
        } else {
            // Not downloaded, load in background thread
            DispatchQueue.global(qos: .userInteractive).async {
                if let data = try? Data(contentsOf: self.url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.uiImage = image
                    }
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

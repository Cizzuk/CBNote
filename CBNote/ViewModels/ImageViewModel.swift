//
//  ImageViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import SwiftUI
import Combine

class ImageViewModel: ObservableObject {
    let url: URL
    @Published var uiImage: UIImage?
    
    init(url: URL) {
        self.url = url
    }
    
    func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: self.url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }
    }
}

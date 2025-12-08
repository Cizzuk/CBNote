//
//  ImageView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI

struct ImageView: View {
    @StateObject private var viewModel: ImageViewModel
    
    init(url: URL) {
        _viewModel = StateObject(wrappedValue: ImageViewModel(url: url))
    }
    
    var body: some View {
        if let uiImage = viewModel.uiImage {
            // Calculate max height from screen size
            let maxHeight: CGFloat = {
                if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    return window.screen.bounds.height * 0.8
                } else {
                    return .infinity
                }
            }()
            
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(shouldPixelate(uiImage) ? .none : .medium)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .onAppear(perform: viewModel.loadImage)
        }
    }
    
    private func shouldPixelate(_ image: UIImage) -> Bool {
        image.size.width <= 256 && image.size.height <= 256
    }
}

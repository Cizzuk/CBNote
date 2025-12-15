//
//  ImageView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI

struct ImageView: View {
    @StateObject private var viewModel: ImageViewModel
    @State private var maxHeight: CGFloat = .infinity
    
    init(url: URL) {
        _viewModel = StateObject(wrappedValue: ImageViewModel(url: url))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let uiImage = viewModel.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(shouldPixelate(uiImage) ? .none : .medium)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .center)
                    .cornerRadius(16)
                    .onAppear {
                        // Calculate max height from screen size
                        if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            maxHeight = window.screen.bounds.height * 0.8
                        } else {
                            maxHeight = .infinity
                        }
                    }
            } else {
                AnyFileItem(url: viewModel.url)
            }
        }
        .onAppear(perform: viewModel.loadImage)
    }
    
    private func shouldPixelate(_ image: UIImage) -> Bool {
        image.size.width <= 256 && image.size.height <= 256
    }
}

//
//  ImageView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI

struct ImageView: View {
    @StateObject private var vm: ImageViewModel
    @State private var maxHeight: CGFloat = .infinity
    private let imagePreviewMode: ImagePreviewMode
    
    init(url: URL, imagePreviewMode: ImagePreviewMode) {
        _vm = StateObject(wrappedValue: ImageViewModel(url: url))
        self.imagePreviewMode = imagePreviewMode
    }
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let uiImage = vm.uiImage {
                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(shouldPixelate(uiImage) ? .none : .medium)
                        .scaledToFit()
                        .frame(alignment: .center)
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                .onAppear {
                    // Calculate max height from screen size
                    if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        maxHeight = window.screen.bounds.height * 0.8
                        if imagePreviewMode == .small && maxHeight > 200 {
                            maxHeight = 200
                        }
                    } else {
                        if imagePreviewMode == .small {
                            maxHeight = 200
                        } else {
                            maxHeight = .infinity
                        }
                    }
                }
            } else {
                AnyFileItem(url: vm.url)
            }
        }
        .transition(.opacity)
        .animation(.easeOut(duration: 0.3), value: vm.isLoading)
        .onAppear(perform: vm.loadImage)
        .onReceive(NotificationCenter.default.publisher(for: .noteListRefreshAttempt)) { _ in
            vm.loadImage()
        }
    }
    
    private func shouldPixelate(_ image: UIImage) -> Bool {
        image.size.width <= 256 && image.size.height <= 256
    }
}

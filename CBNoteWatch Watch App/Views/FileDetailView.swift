//
//  FileDetailView.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/07.
//

import SwiftUI

struct FileDetailView: View {
    @ObservedObject var viewModel: WatchViewModel
    let file: WatchViewModel.FileItem
    @State private var content: Any?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let text = content as? String {
                if text.isEmpty {
                    Text("File is empty")
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        Text(text)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else if let image = content as? UIImage {
                ScrollView {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text("Failed to load content.")
                Text("Could not load file or unsupported file type.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle(file.name)
        .onAppear {
            viewModel.getFileContent(fileName: file.name) { result in
                self.content = result
                self.isLoading = false
            }
        }
    }
}

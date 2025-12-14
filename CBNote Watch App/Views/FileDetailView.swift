//
//  FileDetailView.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/07.
//

import SwiftUI

struct FileDetailView: View {
    @StateObject private var model = WatchConnectionModel.shared
    
    let file: WatchFileItem
    @State private var content: WatchFileContent?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let content = content {
                switch content {
                case .text(let text):
                    if text.isEmpty {
                        Text("Note is empty")
                            .foregroundColor(.gray)
                    } else {
                        ScrollView {
                            Text(text)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                case .image(let data):
                    if let image = UIImage(data: data) {
                        ScrollView {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        Text("Failed to load image.")
                    }
                case .unsupported:
                    Text("Unsupported file type.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text("Failed to load content.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle(file.name)
        .onAppear {
            model.fetchFileContent(fileName: file.name) { result in
                self.content = result
                self.isLoading = false
            }
        }
        .alert(isPresented: $model.showError) {
            Alert(title: Text("Error"),
                  message: Text(model.errorMessage ?? "Unknown error"),
                  dismissButton: .default(Text("OK"))
            )
        }
    }
}

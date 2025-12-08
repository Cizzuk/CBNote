//
//  FileRow.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI

struct FileRow: View {
    let url: URL
    let onPreview: () -> Void
    @StateObject private var viewModel: FileRowViewModel
    
    init(url: URL, onPreview: @escaping () -> Void = {}) {
        self.url = url
        self.onPreview = onPreview
        _viewModel = StateObject(wrappedValue: FileRowViewModel(url: url))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if FileTypes.isEditableText(url) {
                TextField("New Note", text: $viewModel.text, axis: .vertical)
                    .onChange(of: viewModel.text) {
                        viewModel.saveText()
                    }
            } else if FileTypes.isPreviewableImage(url) {
                Button(action: onPreview) {
                    ImageView(url: url)
                }
                .accessibilityLabel(FileTypes.name(for: url))
            } else {
                Button(action: onPreview) {
                    AnyFileItem(text: FileTypes.name(for: url), systemImage: FileTypes.systemImage(for: url))
                }
            }
            
            Spacer()
            HStack {
                Text(url.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            viewModel.loadContent()
        }
    }
    
    struct AnyFileItem: View {
        var text: String
        var systemImage: String
        
        var body: some View {
            HStack {
                Image(systemName: systemImage)
                Text(text)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

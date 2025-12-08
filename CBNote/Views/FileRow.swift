//
//  FileRow.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI
import AVKit

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
            if FileTypes.isText(url) {
                TextField("New Note", text: $viewModel.text, axis: .vertical)
                    .onChange(of: viewModel.text) {
                        viewModel.saveText()
                    }
            } else if FileTypes.isImage(url) {
                Button(action: onPreview) {
                    ImageView(url: url)
                }
            } else if FileTypes.isVideo(url) {
                Button(action: onPreview) {
                    AnyFileItem(text: "Video File", systemImage: "video")
                }
            } else if FileTypes.isAudio(url) {
                Button(action: onPreview) {
                    AnyFileItem(text: "Audio File", systemImage: "waveform")
                }
            } else {
                Button(action: onPreview) {
                    AnyFileItem(text: "Unknown File Type", systemImage: "doc")
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
        var text: LocalizedStringResource
        var systemImage: String
        
        var body: some View {
            Image(systemName: systemImage)
                .accessibilityLabel(text)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

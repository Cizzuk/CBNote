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
    
    init(url: URL, onPreview: @escaping () -> Void = {}) {
        self.url = url
        self.onPreview = onPreview
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if !FileManager.default.fileExists(atPath: url.path) {
                AnyFileNotFoundItem(url: url)
            } else if FileTypes.isEditableText(url) {
                TextEditView(url: url)
            } else if FileTypes.isPreviewableImage(url) {
                Button(action: onPreview) {
                    ImageView(url: url)
                }
                .accessibilityLabel(FileTypes.name(for: url))
            } else {
                Button(action: onPreview) {
                    AnyFileItem(url: url)
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
    }
}

struct AnyFileItem: View {
    var url: URL
    
    var body: some View {
        HStack {
            Image(systemName: FileTypes.systemImage(for: url))
            Text(FileTypes.name(for: url))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct AnyFileNotFoundItem: View {
    var url: URL
    
    var body: some View {
        HStack {
            Image(systemName: FileTypes.systemImageQuestionmark(for: url))
            Text(url.hasDirectoryPath ? "Folder Not Found" : "File Not Found")
        }
        .foregroundStyle(.gray)
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

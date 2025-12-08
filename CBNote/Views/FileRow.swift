//
//  FileRow.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI

struct FileRow: View {
    let url: URL
    @StateObject private var viewModel: FileRowViewModel
    
    init(url: URL) {
        self.url = url
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
                ImageView(url: url)
            } else {
                HStack {
                    Image(systemName: "doc")
                    Text(url.lastPathComponent)
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
}

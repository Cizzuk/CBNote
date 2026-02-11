//
//  MainView+FileRow.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/11.
//

import SwiftUI

extension MainView {
    // MARK: - File Row View
    func fileRow(url: URL, onPreview: @escaping () -> Void) -> some View {
        FileRow(url: url, showImagePreview: showImagePreview, onPreview: onPreview)
            .id("\(url.absoluteString)")
            .onDrag() {
                return NSItemProvider(contentsOf: url) ?? NSItemProvider()
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(action: { viewModel.copyFile(at: url) }) {
                    Label("Copy", systemImage: "document.on.document")
                }
                .tint(.accent)
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.indigo)
            }
            .contextMenu {
                fileContextMenu(url: url)
            }
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private func fileContextMenu(url: URL) -> some View {
        Button(action: { viewModel.pinUnpinFile(at: url) }) {
            if viewModel.isFilePinned(url) {
                Label("Unpin", systemImage: "pin.slash")
            } else {
                Label("Pin", systemImage: "pin")
            }
        }
        Divider()
        
        if FileTypes.isEditableText(url) {
            #if !targetEnvironment(macCatalyst)
            // Translate
            Button(action: { viewModel.translateFile(at: url) }) {
                Label("Translate", systemImage: "translate")
            }
            #endif
            // Open in Browser
            Button(action: { viewModel.openInBrowser(at: url) }) {
                Label("Open in Browser", systemImage: "safari")
            }
            Divider()
        }
        
        if FileTypes.isPreviewableImage(url) && TrueDevice.isSaveToPhotosAvailable() {
            // Save to Photos
            Button(action: { viewModel.saveImageToPhotos(at: url) }) {
                Label("Save to Photos", systemImage: "photo.badge.arrow.down")
            }
            Divider()
        }
        
        Button(action: { viewModel.copyFile(at: url) }) {
            Label("Copy", systemImage: "document.on.document")
        }
        ShareLink(item: url) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button(action: { previewURL = url }) {
            Label("Quick Look", systemImage: "eye")
        }
        Divider()
        
        Button(action: { viewModel.startRenaming(at: url) }) {
            Label("Rename", systemImage: "pencil")
        }
        Button(role: .destructive) {
            viewModel.deleteFile(at: url)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

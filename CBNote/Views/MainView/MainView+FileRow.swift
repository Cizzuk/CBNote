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
                Button(action: { vm.copyFile(at: url) }) {
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
        Button(action: { vm.pinUnpinFile(at: url) }) {
            if vm.isFilePinned(url) {
                Label("Unpin", systemImage: "pin.slash")
            } else {
                Label("Pin", systemImage: "pin")
            }
        }
        Divider()
        
        if FileTypes.isEditableText(url) {
            #if !targetEnvironment(macCatalyst)
            // Translate
            Button(action: { vm.translateFile(at: url) }) {
                Label("Translate", systemImage: "translate")
            }
            #endif
            // Open in Browser
            Button(action: { vm.openInBrowser(at: url) }) {
                Label("Open in Browser", systemImage: "safari")
            }
            Divider()
        }
        
        if FileTypes.isPreviewableImage(url) && TrueDevice.isSaveToPhotosAllowed() {
            // Save to Photos
            Button(action: { vm.saveImageToPhotos(at: url) }) {
                Label("Save to Photos", systemImage: "photo.badge.arrow.down")
            }
            Divider()
        }
        
        Button(action: { vm.copyFile(at: url) }) {
            Label("Copy", systemImage: "document.on.document")
        }
        ShareLink(item: url) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button(action: { previewURL = url }) {
            Label("Quick Look", systemImage: "eye")
        }
        Divider()
        
        Button(action: { vm.startRenaming(at: url) }) {
            Label("Rename", systemImage: "pencil")
        }
        Button(role: .destructive) {
            vm.deleteFile(at: url)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

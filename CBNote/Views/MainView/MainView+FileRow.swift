//
//  MainView+FileRow.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/11.
//

import SwiftUI

extension MainView {
    // MARK: - File Row View
    func fileRow(url: URL, onPreview: @escaping () -> Void, allowsPin: Bool = true) -> some View {
        FileRow(url: url, onPreview: onPreview)
            .id("\(url.absoluteString)")
            .onDrag {
                return NSItemProvider(contentsOf: url) ?? NSItemProvider()
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if !FileTypes.isDirectory(url) {
                    Button(action: { vm.copyFile(at: url) }) {
                        Label("Copy", systemImage: "document.on.document")
                    }
                    .tint(.accent)
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.indigo)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: !FileTypes.isDirectory(url)) {
                if allowsPin && vm.isFilePinned(url) {
                    Button(action: { vm.pinUnpinFile(at: url) }) {
                        Label("Unpin", systemImage: "pin.slash")
                    }
                    .tint(.yellow)
                } else {
                    Button(role: .destructive) {
                        vm.deleteFile(at: url)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button(action: { vm.startRenaming(at: url) }) {
                        Label("Rename", systemImage: "pencil")
                    }
                }
            }
            .contextMenu {
                fileContextMenu(url: url, allowsPin: allowsPin)
            }
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func fileContextMenu(url: URL, allowsPin: Bool) -> some View {
        if allowsPin {
            Button(action: { vm.pinUnpinFile(at: url) }) {
                if vm.isFilePinned(url) {
                    Label("Unpin", systemImage: "pin.slash")
                } else {
                    Label("Pin", systemImage: "pin")
                }
            }
            Divider()
        }

        if !FileTypes.isDirectory(url), FileTypes.isEditableText(url) {
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

        if !FileTypes.isDirectory(url), FileTypes.isPreviewableImage(url), TrueDevice.isSaveToPhotosAllowed() {
            // Save to Photos
            Button(action: { vm.saveImageToPhotos(at: url) }) {
                Label("Save to Photos", systemImage: "photo.badge.arrow.down")
            }
            Divider()
        }

        if !FileTypes.isDirectory(url) {
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
        }

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

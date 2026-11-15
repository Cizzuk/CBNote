//
//  FileListView.swift
//  CBNote Watch
//
//  Created by Cizzuk on 2025/12/14.
//

import SwiftUI

struct FileListView: View {
    @StateObject private var model = WatchConnectionModel.shared

    let name: String
    let directoryId: String
    var relativePath: String = ""

    @State private var pinnedFiles: [WatchFileItem] = []
    @State private var unpinnedFiles: [WatchFileItem] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if pinnedFiles.isEmpty && unpinnedFiles.isEmpty {
                Text("No notes yet.")
                    .multilineTextAlignment(.center)
            } else {
                List {
                    if !pinnedFiles.isEmpty && relativePath.isEmpty {
                        Section {
                            ForEach(pinnedFiles) { file in
                                fileRow(file: file)
                            }
                        } header: {
                            Label("Pinned Notes", systemImage: "pin.fill")
                        }
                    }

                    Section {
                        ForEach(unpinnedFiles) { file in
                            fileRow(file: file)
                        }
                    }
                }
            }
        }
        .navigationTitle(name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { reload() }) {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            reload()
        }
        .alert(isPresented: $model.showError) {
            Alert(
                title: Text("Error"),
                message: Text(verbatim: model.errorMessage ?? String(localized: "Unknown error")),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func reload() {
        isLoading = true
        model.fetchFiles(directoryId: directoryId, relativePath: relativePath) { pinned, unpinned in
            pinnedFiles = pinned
            unpinnedFiles = unpinned
            isLoading = false
        }
    }

    @ViewBuilder
    private func fileRow(file: WatchFileItem) -> some View {
        if file.isDirectory {
            NavigationLink(
                destination: FileListView(name: file.name, directoryId: directoryId, relativePath: file.relativePath)
            ) {
                rowLabel(file: file)
            }
        } else {
            NavigationLink(destination: FileDetailView(file: file)) {
                rowLabel(file: file)
            }
        }
    }

    private func rowLabel(file: WatchFileItem) -> some View {
        VStack(alignment: .leading) {
            if let preview = file.preview {
                Text(preview)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Divider()
            }
            Label(file.name, systemImage: file.systemImage)
                .font(.caption)
        }
    }
}

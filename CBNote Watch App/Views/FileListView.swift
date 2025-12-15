//
//  FileListView.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/14.
//

import SwiftUI

struct FileListView: View {
    @StateObject private var model = WatchConnectionModel.shared
    
    let name: String
    let directoryId: String
    
    var body: some View {
        Group {
            if model.isLoading {
                ProgressView()
            } else if model.pinnedFiles.isEmpty && model.unpinnedFiles.isEmpty {
                Text("No notes found.")
                    .multilineTextAlignment(.center)
            } else {
                List {
                    if !model.pinnedFiles.isEmpty {
                        Section {
                            ForEach(model.pinnedFiles) { file in
                                fileRow(file: file)
                            }
                        } header: {
                            Label("Pinned Notes", systemImage: "pin.fill")
                        }
                    }
                    
                    Section {
                        ForEach(model.unpinnedFiles) { file in
                            fileRow(file: file)
                        }
                    }
                }
            }
        }
        .navigationTitle(name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { model.fetchFiles(directoryId: directoryId) }) {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(model.isLoading)
            }
        }
        .onAppear {
            model.fetchFiles(directoryId: directoryId)
        }
        .alert(isPresented: $model.showError) {
            Alert(title: Text("Error"),
                  message: Text(model.errorMessage ?? "Unknown error"),
                  dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func fileRow(file: WatchFileItem) -> some View {
        NavigationLink(destination: FileDetailView(file: file)) {
            VStack(alignment: .leading) {
                if let preview = file.preview {
                    Text(preview)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    Divider()
                }
                Label(file.name, systemImage: FileTypes.systemImage(for: file.id))
                    .font(.caption)
            }
        }
    }
}

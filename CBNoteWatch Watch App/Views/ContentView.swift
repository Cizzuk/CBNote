//
//  ContentView.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/07.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.errorMessage {
                    VStack {
                        Label(error, systemImage: "exclamationmark.triangle")
                        Button("Retry") {
                            viewModel.loadFiles()
                        }
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.files.isEmpty {
                    Text("No notes yet. Add notes from your iPhone first.")
                        .multilineTextAlignment(.center)
                } else {
                    List(viewModel.files) { file in
                        NavigationLink(value: file) {
                            VStack(alignment: .leading) {
                                if let preview = file.preview {
                                    Text(preview)
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                    Divider()
                                }
                                Label(file.name, systemImage: FileTypes.systemImage(for: file.url))
                                    .font(.caption)
                            }
                        }
                    }
                    .navigationDestination(for: WatchViewModel.FileItem.self) { file in
                        FileDetailView(viewModel: viewModel, file: file)
                    }
                }
            }
            .navigationTitle("CBNote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: viewModel.loadFiles) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear() {
            viewModel.loadFiles()
        }
    }
}

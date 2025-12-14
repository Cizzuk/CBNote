//
//  ContentView.swift
//  CBNote Watch App
//
//  Created by Cizzuk on 2025/12/07.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = WatchConnectionModel.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if model.isLoading && model.directories.isEmpty {
                    ProgressView()
                } else if model.directories.isEmpty {
                    VStack {
                        Text("No locations available.")
                        Button("Reload") {
                            model.fetchDirectories()
                        }
                    }
                } else {
                    List(model.directories) { dir in
                        NavigationLink(destination: FileListView(name: dir.name, directoryId: dir.id)) {
                            Label(dir.name, systemImage: dir.systemImage)
                        }
                    }
                }
            }
            .navigationTitle("CBNote")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { model.fetchDirectories() }) {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.isLoading)
                }
            }
            .alert(isPresented: $model.showError) {
                Alert(title: Text("Error"),
                      message: Text(model.errorMessage ?? "Unknown error"),
                      dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            model.fetchDirectories()
        }
    }
}


//
//  MainView+Toolbar.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/11.
//

import SwiftUI

extension MainView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // MARK: - Primary Actions
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { viewModel.createNewNote() }) {
                Label("Add New Note", systemImage: "square.and.pencil")
            }
            
            Button(action: { viewModel.addAndPaste() }) {
                Label("Paste", systemImage: "document.on.clipboard")
            }
            .confirmationDialog(
                "Paste Failed",
                isPresented: $viewModel.showPasteError
            ) {
                Button("OK", role: .close) {}
            } message: {
                Text("No valid content found in clipboard to paste.")
            }
        }
        
        // MARK: - Secondary Actions
        ToolbarItemGroup(placement: .secondaryAction) {
            if TrueDevice.isCameraAvailable {
                Button(action: { viewModel.showCamera = true }) {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            
            Button(action: { viewModel.showRecorder = true }) {
                Label("Record Audio", systemImage: "waveform.badge.microphone")
            }
            
            Button(action: { showFileImporter = true }) {
                Label("Import from Files", systemImage: "document")
            }
        }
        
        // MARK: - Top Left
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button(action: { viewModel.showSettings = true }) {
                    Label("App Settings", systemImage: "gearshape")
                }
                
                Divider()
                
                // iCloud/On-Device
                Section {
                    ForEach(DocumentDir.availableDirs, id: \.self) { type in
                        Button(action: { viewModel.setDocumentDir(type: type) }) {
                            HStack {
                                if viewModel.documentDir == type {
                                    Image(systemName: "checkmark")
                                }
                                Text(type.localizedName)
                            }
                        }
                        .accessibility(addTraits: viewModel.documentDir == type ? [.isSelected] : [])
                    }
                } header: {
                    Text("Location")
                }
                
                Divider()
                
                // Sort
                Section {
                    ForEach(SortKey.allCases, id: \.self) { key in
                        Button(action: { viewModel.toggleSort(key: key) }) {
                            HStack {
                                if viewModel.sortKey == key {
                                    Image(systemName: viewModel.sortDirection == .descending ? "chevron.down" : "chevron.up")
                                }
                                Text(key.localizedName)
                            }
                        }
                        .accessibility(addTraits: viewModel.sortKey == key ? [.isSelected] : [])
                        .accessibilityHint(viewModel.sortKey == key ? "Currently sorted in \(viewModel.sortDirection.localizedName) order." : "")
                    }
                } header: {
                    Text("Sort By")
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .matchedTransitionSource(id: id_openSettingsButton, in: ns_settingsView)
        }
        
        // MARK: - Keyboard
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Label("Done", systemImage: "checkmark")
            }
        }
    }
}

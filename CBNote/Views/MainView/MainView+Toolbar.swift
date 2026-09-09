//
//  MainView+Toolbar.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/11.
//

import PhotosUI
import SwiftUI

extension MainView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // MARK: - Primary Actions
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { vm.createNewNote() }) {
                Label("Add New Note", systemImage: "square.and.pencil")
            }
            
            Button(action: { vm.addAndPaste() }) {
                Label("Paste", systemImage: "document.on.clipboard")
            }
            .confirmationDialog(
                "Paste Failed",
                isPresented: $vm.showPasteError
            ) {
                Button("OK", role: .close) {}
            } message: {
                Text("No valid content found in clipboard to paste.")
            }
        }
        
        // MARK: - Secondary Actions
        ToolbarItemGroup(placement: .secondaryAction) {
            if TrueDevice.isCameraAvailable {
                Button(action: { vm.showCamera = true }) {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            
            Button(action: { vm.showRecorder = true }) {
                Label("Record Audio", systemImage: "waveform.badge.microphone")
            }
            
            Button(action: { showFileImporter = true }) {
                Label("Import from Files", systemImage: "document")
            }
            
            PhotosPicker(selection: $selectedPhoto) {
                Label("Import from Photos", systemImage: "photo")
            }
        }
        
        // MARK: - Top Left
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button(action: { vm.showSettings = true }) {
                    Label("App Settings", systemImage: "gearshape")
                        .labelStyle(.titleAndIcon)
                }
                
                Divider()
                
                // iCloud/On-Device
                Section {
                    ForEach(DocumentDir.availableDirs, id: \.self) { type in
                        Button(action: { vm.setDocumentDir(type: type) }) {
                            if vm.documentDir == type {
                                Label(type.localizedName, systemImage: "checkmark")
                                    .labelStyle(.titleAndIcon)
                            } else {
                                Label(type.localizedName, image: "EmptySymbol")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .accessibility(addTraits: vm.documentDir == type ? [.isSelected] : [])
                    }
                } header: {
                    Text("Location")
                }
                
                Divider()
                
                // Sort
                Section {
                    ForEach(SortKey.allCases, id: \.self) { key in
                        Button(action: { vm.toggleSort(key: key) }) {
                            if vm.sortKey == key {
                                Label(
                                    key.localizedName,
                                    systemImage: vm.sortDirection == .descending ? "chevron.down" : "chevron.up"
                                )
                                .labelStyle(.titleAndIcon)
                            } else {
                                Label(key.localizedName, image: "EmptySymbol")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .accessibility(addTraits: vm.sortKey == key ? [.isSelected] : [])
                        .accessibilityHint(vm.sortKey == key ? "Currently sorted in \(vm.sortDirection.localizedName) order." : "")
                    }
                } header: {
                    Text("Sort By")
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
            }
            .labelStyle(.titleAndIcon)
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

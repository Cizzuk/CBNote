//
//  MainView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import SwiftUI
import QuickLook

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var previewURL: URL?
    @State private var isExpandPinnedSection = true
    @State private var refreshID = UUID() // Update this to force refresh file views

    var body: some View {
        ZStack {
            if viewModel.showDummyCamera {
                DummyCameraView()
            }
            
            NavigationStack {
                List {
                    // Empty State
                    if viewModel.pinnedFiles.isEmpty && viewModel.unpinnedFiles.isEmpty {
                        Section {} footer: {
                            if viewModel.searchQuery.isEmpty {
                                Text("No notes yet. Tap the + button to add a new note.")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                VStack {
                                    Label("No Results", systemImage: "magnifyingglass")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .font(.headline)
                                    Spacer()
                                    Text("for \"\(viewModel.searchQuery)\".")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // Pinned Files
                    if !viewModel.pinnedFiles.isEmpty {
                        Section {
                            if isExpandPinnedSection {
                                ForEach(viewModel.pinnedFiles, id: \.self) { url in
                                    fileRow(url: url, onPreview: { previewURL = url })
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(action: { viewModel.pinUnpinFile(at: url) }) {
                                                if viewModel.isFilePinned(url) {
                                                    Label("Unpin", systemImage: "pin.slash")
                                                } else {
                                                    Label("Pin", systemImage: "pin")
                                                }
                                            }
                                            .tint(.yellow)
                                        }
                                }
                            }
                        } header: {
                            Button {
                                withAnimation {
                                    isExpandPinnedSection.toggle()
                                }
                            } label: {
                                HStack {
                                    Label("Pinned Notes", systemImage: "pin.fill")
                                    Image(systemName: isExpandPinnedSection ? "chevron.down" : "chevron.forward")
                                }
                            }
                            .foregroundColor(.secondary)
                            .accessibilityValue(isExpandPinnedSection ? "Expanded" : "Collapsed")
                        }
                    }
                    
                    // Unpinned Files
                    Section {
                        ForEach(viewModel.unpinnedFiles, id: \.self) { url in
                            fileRow(url: url, onPreview: { previewURL = url })
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteFile(at: url)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button(action: { viewModel.startRenaming(url: url) }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                }
                        }
                    }
                    
                    // MARK: - End of List
                }
                .animation(.default, value: viewModel.pinnedFiles)
                .animation(.default, value: viewModel.unpinnedFiles)
                .searchable(text: $viewModel.searchQuery, prompt: "Search Notes")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: { viewModel.showCamera(true) }) {
                            Label("Camera", systemImage: "camera")
                        }
                        .popover(isPresented: $viewModel.showCamera_popover) {
                            CameraView { data in
                                viewModel.saveCapturedImage(data: data)
                            }
                            .presentationCompactAdaptation(.fullScreenCover)
                        }
                        Button(action: { Task { await viewModel.addAndPaste() } }) {
                            Label("Paste", systemImage: "document.on.clipboard")
                        }
                        .popover(isPresented: $viewModel.showPasteError) {
                            Text("No valid content found in clipboard to paste.")
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        }
                        Button(action: viewModel.createNewNote) {
                            Label("Add New Note", systemImage: "plus")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button(action: { viewModel.showSettings(true) }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .popover(isPresented: $viewModel.showSettings_popover) {
                            SettingsView()
                                .presentationDetents([.large])
                                .presentationCompactAdaptation(.sheet)
                        }
                        Menu {
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
                                }
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
                                }
                            } header: {
                                Text("Sort By")
                            }
                        } label: {
                            Label("Option", systemImage: "ellipsis")
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                    }
                }
                .refreshable {
                    viewModel.checkLockedCameraCaptures()
                    viewModel.loadFiles()
                    refreshID = UUID()
                }
                .onAppear {
                    viewModel.checkLockedCameraCaptures()
                    viewModel.checkAutoPaste()
                    viewModel.loadFiles()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    viewModel.checkLockedCameraCaptures()
                    viewModel.checkAutoPaste()
                    viewModel.loadFiles()
                }
                .onReceive(NotificationCenter.default.publisher(for: .cameraControlDidActivate)) { _ in
                    viewModel.handleCameraControlAction()
                }
                .onReceive(NotificationCenter.default.publisher(for: .openAppIntentPerformed)) { action in
                    if let option = action.object as? OpenAppOption {
                        viewModel.openApp(with: option)
                    }
                }
                .fullScreenCover(isPresented: $viewModel.showCamera_sheet) {
                    CameraView { data in
                        viewModel.saveCapturedImage(data: data)
                    }
                }
                .sheet(isPresented: $viewModel.showSettings_sheet) {
                    SettingsView()
                }
                .alert("Rename", isPresented: $viewModel.isRenaming) {
                    TextField("New Name", text: $viewModel.newName)
                    Button("Cancel", role: .cancel) {}
                    Button("Rename", role: .confirm) {
                        viewModel.renameFile()
                    }
                    .disabled(!viewModel.isValidFileName(viewModel.newName))
                }
                .quickLookPreview($previewURL)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - File Row View
    
    func fileRow(url: URL, onPreview: @escaping () -> Void) -> some View {
        FileRow(url: url, onPreview: onPreview)
            .id("\(url.absoluteString)-\(refreshID)")
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
                Button(action: { viewModel.pinUnpinFile(at: url) }) {
                    if viewModel.isFilePinned(url) {
                        Label("Unpin", systemImage: "pin.slash")
                    } else {
                        Label("Pin", systemImage: "pin")
                    }
                }
                Divider()
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
                Button(action: { viewModel.startRenaming(url: url) }) {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    viewModel.deleteFile(at: url)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

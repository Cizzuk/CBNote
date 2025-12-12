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

    var body: some View {
        ZStack {
            if viewModel.showDummyCamera {
                DummyCameraView()
            }
            
            NavigationStack {
                List {
                    if viewModel.files.isEmpty {
                        Section {} footer: {
                            Text("No notes yet. Tap the + button to add a new note.")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    
                    if !viewModel.pinnedFiles.isEmpty {
                        Section {
                            ForEach(viewModel.pinnedFiles, id: \.self) { url in
                                fileRow(url: url, onPreview: { previewURL = url })
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.pinUnpinFile(at: url)
                                        } label: {
                                            if viewModel.isFilePinned(url) {
                                                Label("Unpin", systemImage: "pin.slash")
                                            } else {
                                                Label("Pin", systemImage: "pin")
                                            }
                                        }
                                        .tint(.yellow)
                                    }
                            }
                        } header: {
                            Label("Pinned Notes", systemImage: "pin.fill")
                        }
                    }
                    
                    Section {
                        ForEach(viewModel.files, id: \.self) { url in
                            if !viewModel.isFilePinned(url) {
                                fileRow(url: url, onPreview: { previewURL = url })
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.deleteFile(at: url)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            viewModel.startRenaming(url: url)
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                    }
                            }
                        }
                        .onDelete(perform: viewModel.deleteFile)
                    }
                }
                .animation(.default, value: viewModel.files)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: { viewModel.showCamera = true }) {
                            Label("Camera", systemImage: viewModel.showCamera ? "camera.fill" : "camera")
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
                        Button(action: { viewModel.showSettings = true }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        Menu {
                            // Reserved for iCloud/On-Device
                            // Divider()
                            
                            Section {
                                ForEach(SortKey.allCases, id: \.self) { key in
                                    Button {
                                        viewModel.toggleSort(key: key)
                                    } label: {
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
                .sheet(isPresented: $viewModel.showCamera) {
                    CameraView { data in
                        viewModel.saveCapturedImage(data: data)
                    }
                }
                .sheet(isPresented: $viewModel.showSettings) {
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
    
    func fileRow(url: URL, onPreview: @escaping () -> Void) -> some View {
        FileRow(url: url, onPreview: onPreview)
            .onDrag() {
                return NSItemProvider(contentsOf: url) ?? NSItemProvider()
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    viewModel.copyFile(at: url)
                } label: {
                    Label("Copy", systemImage: "document.on.document")
                }
                .tint(.accent)
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.indigo)
            }
            .contextMenu {
                Button {
                    viewModel.pinUnpinFile(at: url)
                } label: {
                    if viewModel.isFilePinned(url) {
                        Label("Unpin", systemImage: "pin.slash")
                    } else {
                        Label("Pin", systemImage: "pin")
                    }
                }
                Divider()
                Button {
                    viewModel.copyFile(at: url)
                } label: {
                    Label("Copy", systemImage: "document.on.document")
                }
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button {
                    previewURL = url
                } label: {
                    Label("Quick Look", systemImage: "eye")
                }
                Divider()
                Button {
                    viewModel.startRenaming(url: url)
                } label: {
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

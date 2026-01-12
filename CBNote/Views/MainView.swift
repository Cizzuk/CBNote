//
//  MainView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/02.
//

import QuickLook
import SwiftUI
import Translation

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion
    @StateObject private var viewModel = MainViewModel()
    @State private var previewURL: URL?
    @State private var isExpandPinnedSection = true
    @AppStorage("showImagePreview") private var showImagePreview: Bool = true
    @AppStorage("enableNoteListAnimations") private var enableNoteListAnimations: Bool = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    if let dummyCameraView = viewModel.dummyCamera?.view {
                        dummyCameraView
                    }
                    
                    ScrollViewReader { proxy in
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
                                        withAnimation(.easeOut) {
                                            isExpandPinnedSection.toggle()
                                        }
                                    } label: {
                                        HStack {
                                            Label("Pinned Notes", systemImage: "pin.fill")
                                            if accessibilityReduceMotion {
                                                Image(systemName: isExpandPinnedSection ? "chevron.down" : "chevron.forward")
                                            } else {
                                                Image(systemName: "chevron.down")
                                                    .rotationEffect(.degrees(isExpandPinnedSection ? 0 : -90))
                                            }
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
                                            Button(action: { viewModel.startRenaming(at: url) }) {
                                                Label("Rename", systemImage: "pencil")
                                            }
                                        }
                                }
                            }
                        } // List
                        // MARK: - List Config
                        .animation(enableNoteListAnimations ? .easeOut : nil, value: viewModel.pinnedFiles)
                        .animation(enableNoteListAnimations ? .easeOut : nil, value: viewModel.unpinnedFiles)
                        .refreshable {
                            viewModel.refreshFiles()
                            // To reduce View jitter
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                        .safeAreaPadding(.horizontal, geo.size.width > 800 ? (geo.size.width - 800) / 2 : 0)
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.unpinnedFiles) {
                            guard let scrollPos = viewModel.newFileURLToScroll else { return }
                            DispatchQueue.global(qos: .userInteractive).async {
                                withAnimation(.easeOut) {
                                    proxy.scrollTo("\(scrollPos.absoluteString)")
                                }
                                DispatchQueue.main.async {
                                    self.viewModel.newFileURLToScroll = nil
                                }
                            }
                        }
                    } // ScrollViewReader
                } // ZStack
                // MARK: - View Config
                .searchable(text: $viewModel.searchQuery, prompt: "Search Notes")
                .toolbar {
                    // Top Right
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if TrueDevice.isCameraAvailable {
                            Button(action: { viewModel.showCamera = true }) {
                                Label("Camera", systemImage: "camera")
                            }
                        }
                        Button(action: { viewModel.addAndPaste() }) {
                            Label("Paste", systemImage: "document.on.clipboard")
                        }
                        #if targetEnvironment(macCatalyst)
                        .alert("No valid content found in clipboard to paste.", isPresented: $viewModel.showPasteError) {
                            Button("OK", role: .cancel) {}
                        }
                        #else
                        .popover(isPresented: $viewModel.showPasteError) {
                            Text("No valid content found in clipboard to paste.")
                                .frame(width: 250)
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        }
                        #endif
                        Button(action: viewModel.createNewNote) {
                            Label("Add New Note", systemImage: "plus")
                        }
                    }
                    // Top Left
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button(action: { viewModel.showSettings = true }) {
                            Label("Settings", systemImage: "gearshape")
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
                            Label("Options", systemImage: "ellipsis")
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
                } // toolbar
                .quickLookPreview($previewURL)
                #if !targetEnvironment(macCatalyst)
                .translationPresentation(isPresented: $viewModel.showTranslation, text: viewModel.translationText)
                .fullScreenCover(isPresented: $viewModel.showCamera) {
                    CameraView { data in
                        viewModel.saveCapturedImage(data: data)
                    }
                }
                #endif
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
                // MARK: - Events
                .onAppear { viewModel.onAppear() }
                .onChange(of: scenePhase) { viewModel.onChange(scenePhase: scenePhase) }
                // Opening from Camera Control
                .onReceive(NotificationCenter.default.publisher(for: .cameraControlDidActivate)) { _ in
                    viewModel.handleCameraControlAction()
                }
                // Opening from App Intents (Shortcuts, Control Center, Home Screen Shortcut)
                .onReceive(NotificationCenter.default.publisher(for: .openAppIntentPerformed)) { action in
                    if let option = action.object as? OpenAppOption {
                        viewModel.openApp(with: option)
                    }
                }
                // Keyboard Shortcuts
                .onReceive(NotificationCenter.default.publisher(for: .customKeyboardShortcutPerformed)) { action in
                    if let shortcut = action.object as? CustomKeyboardShortcut {
                        viewModel.handleKeyboardShortcut(shortcut: shortcut)
                    }
                }
                .onOpenURL { url in
                    viewModel.handleOpenURL(url: url)
                }
            } // GeometryReader
        } // NavigationStack
        // MARK: - Dummy Curtain
        .opacity(viewModel.showDummyCurtain ? 0.0 : 1.0)
        .fullScreenCover(isPresented: $viewModel.showDummyCurtain) { DummyCurtainView() }
    } // body
    
    // MARK: - File Row View
    func fileRow(url: URL, onPreview: @escaping () -> Void) -> some View {
        FileRow(url: url, showImagePreview: showImagePreview, onPreview: onPreview)
            .id("\(url.absoluteString)")
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
                
                #if !targetEnvironment(macCatalyst)
                if FileTypes.isEditableText(url) {
                    // Translate
                    Button(action: { viewModel.translateFile(at: url) }) {
                        Label("Translate", systemImage: "translate")
                    }
                    // Open in Browser
                    Button(action: { viewModel.openInBrowser(at: url) }) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    Divider()
                }
                #endif
                
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
                
                Button(action: { viewModel.startRenaming(at: url) }) {
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

//
//  MainView+FileList.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/11.
//

import SwiftUI

extension MainView {
    @ViewBuilder
    func fileListView() -> some View {
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
                        pinnedSectionHeader
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
    }
    
    // MARK: - Pinned Section Header
    @ViewBuilder
    private var pinnedSectionHeader: some View {
        Menu {
            Button(action: { viewModel.unpinAll() }) {
                Label("Unpin All", systemImage: "pin.slash")
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
            .onTapGesture {
                // Make the entire header tappable
                withAnimation(.easeOut) {
                    isExpandPinnedSection.toggle()
                }
            }
        } primaryAction: {
            withAnimation(.easeOut) {
                isExpandPinnedSection.toggle()
            }
        }
        .foregroundColor(.secondary)
        .accessibilityValue(isExpandPinnedSection ? "Expanded" : "Collapsed")
    }
}

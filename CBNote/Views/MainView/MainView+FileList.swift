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
                if vm.pinnedFiles.isEmpty && vm.unpinnedFiles.isEmpty {
                    Section {} footer: {
                        if vm.searchQuery.isEmpty {
                            Text("No notes yet.")
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            VStack {
                                Label("No Results", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.headline)
                                Spacer()
                                Text("for \"\(vm.searchQuery)\".")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Pinned Files
                if !vm.pinnedFiles.isEmpty {
                    Section {
                        if isExpandPinnedSection {
                            ForEach(vm.pinnedFiles, id: \.self) { url in
                                fileRow(url: url, onPreview: { previewURL = url })
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(action: { vm.pinUnpinFile(at: url) }) {
                                            if vm.isFilePinned(url) {
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
                    ForEach(vm.unpinnedFiles, id: \.self) { url in
                        fileRow(url: url, onPreview: { previewURL = url })
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.deleteFile(at: url)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button(action: { vm.startRenaming(at: url) }) {
                                    Label("Rename", systemImage: "pencil")
                                }
                            }
                    }
                }
            } // List
            // MARK: - List Config
            .animation(enableNoteListAnimations ? .easeOut : nil, value: vm.pinnedFiles)
            .animation(enableNoteListAnimations ? .easeOut : nil, value: vm.unpinnedFiles)
            .refreshable {
                vm.refreshFiles()
                // To reduce View jitter
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: vm.unpinnedFiles) {
                guard let scrollPos = vm.newFileURLToScroll else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut) {
                        proxy.scrollTo("\(scrollPos.absoluteString)")
                    }
                    self.vm.newFileURLToScroll = nil
                }
            }
        } // ScrollViewReader
    }
    
    // MARK: - Pinned Section Header
    @ViewBuilder
    private var pinnedSectionHeader: some View {
        Menu {
            Button(action: { vm.unpinAll() }) {
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
        .foregroundStyle(.secondary)
        .accessibilityValue(isExpandPinnedSection ? "Expanded" : "Collapsed")
    }
}

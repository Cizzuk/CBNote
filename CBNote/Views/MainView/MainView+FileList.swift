//
//  MainView+FileList.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/11.
//

import Combine
import SwiftUI

private func scrollToNewFile(in files: [URL], proxy: ScrollViewProxy, vm: MainViewModel) {
    guard let target = vm.newFileURLToScroll,
        let rowURL = vm.listedFile(matching: target, in: files)
    else { return }

    let rowID = rowURL.absoluteString
    DispatchQueue.main.async {
        withAnimation(.easeOut) {
            proxy.scrollTo(rowID)
        }
        if let current = vm.newFileURLToScroll,
            NoteService.normalizedDirectoryPath(current) == NoteService.normalizedDirectoryPath(rowURL)
        {
            vm.newFileURLToScroll = nil
        }
    }
}

extension MainView {
    @ViewBuilder
    func fileListView() -> some View {
        ScrollViewReader { proxy in
            List {
                // Empty State
                if vm.pinnedFiles.isEmpty && vm.unpinnedFiles.isEmpty {
                    Section {
                    } footer: {
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
                    }
                }
            }  // List
            // MARK: - List Config
            .refreshable {
                vm.refreshFiles()
                // To reduce View jitter
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            .onChange(of: vm.unpinnedFiles) {
                scrollToNewFile(in: vm.unpinnedFiles, proxy: proxy, vm: vm)
            }
            .onChange(of: vm.newFileURLToScroll) {
                scrollToNewFile(in: vm.unpinnedFiles, proxy: proxy, vm: vm)
            }
        }  // ScrollViewReader
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

    func folderScreen(_ directory: URL) -> some View {
        FolderFileList(directory: directory, vm: vm) { url in
            fileRow(url: url, onPreview: { previewURL = url }, allowsPin: false)
        }
        .toolbar { toolbarContent(showsNavigationItem: false) }
        .navigationTitle(directory.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FolderFileList<RowContent: View>: View {
    let directory: URL
    @ObservedObject var vm: MainViewModel
    let rowContent: (URL) -> RowContent

    @State private var files: [URL] = []
    @State private var searchQuery = ""

    private var visibleFiles: [URL] {
        vm.filterFiles(files, query: searchQuery)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if visibleFiles.isEmpty {
                    Section {
                    } footer: {
                        if searchQuery.isEmpty {
                            Text("No notes yet.")
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            VStack {
                                Label("No Results", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.headline)
                                Spacer()
                                Text("for \"\(searchQuery)\".")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.caption)
                            }
                        }
                    }
                }

                if !visibleFiles.isEmpty {
                    Section {
                        ForEach(visibleFiles, id: \.self) { url in
                            rowContent(url)
                        }
                    }
                }
            }
            .refreshable {
                vm.refreshFiles()
                // To reduce View jitter
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            .onChange(of: files) {
                scrollToNewFile(in: visibleFiles, proxy: proxy, vm: vm)
            }
            .onChange(of: vm.newFileURLToScroll) {
                scrollToNewFile(in: visibleFiles, proxy: proxy, vm: vm)
            }
        }
        .searchable(text: $searchQuery, prompt: "Search Notes")
        .onAppear { reload() }
        .onReceive(vm.noteManager.objectWillChange.receive(on: DispatchQueue.main)) { _ in
            reload()
        }
    }

    private func reload() {
        files = vm.files(in: directory)
    }
}

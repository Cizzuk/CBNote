//
//  TextEditView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/13.
//

import SwiftUI

struct TextEditView: View {
    @StateObject private var vm: TextEditViewModel
    
    init(url: URL) {
        _vm = StateObject(wrappedValue: TextEditViewModel(url: url))
    }
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if vm.isFileEditable {
                TextField("New Note", text: $vm.text, axis: .vertical)
                    .onChange(of: vm.text) {
                        vm.saveText()
                    }
                    .font(vm.textFont())
            } else {
                AnyFileItem(url: vm.url)
            }
        }
        .onAppear {
            vm.loadContent()
        }
        .onReceive(NotificationCenter.default.publisher(for: .noteListRefreshAttempt)) { _ in
            vm.loadContent()
        }
    }
}

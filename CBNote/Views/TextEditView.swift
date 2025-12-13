//
//  TextEditView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/13.
//

import SwiftUI

struct TextEditView: View {
    @StateObject private var viewModel: TextEditViewModel
    
    init(url: URL) {
        _viewModel = StateObject(wrappedValue: TextEditViewModel(url: url))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.isFileEditable {
                TextField("New Note", text: $viewModel.text, axis: .vertical)
                    .onChange(of: viewModel.text) {
                        viewModel.saveText()
                    }
            } else {
                AnyFileItem(url: viewModel.url)
            }
        }
        .onAppear {
            viewModel.loadContent()
        }
    }
}

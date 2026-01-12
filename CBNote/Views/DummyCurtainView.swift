//
//  DummyCurtainView.swift
//  CBNote
//
//  Created by Cizzuk on 2026/01/12.
//

import SwiftUI

struct DummyCurtainView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityLabel("Close Curtain")
                .accessibility(addTraits: [.isModal, .isButton])
                .accessibilityAction(.escape) { dismiss() }
                .onTapGesture { dismiss() }
        }
    }
}

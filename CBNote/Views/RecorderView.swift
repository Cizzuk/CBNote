//
//  RecorderView.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/16.
//

import AVFoundation
import SwiftUI

struct RecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel = RecorderViewModel()
    
    var body: some View {
        NavigationStack {
            
        }
        .presentationDetents([.fraction(0.3)])
    }
}

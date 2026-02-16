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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = RecorderViewModel()
    
    let onRecordingFinished: (URL) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(viewModel.elapsedTimeText)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                
                if viewModel.isRecording {
                    Button(role: .destructive) {
                        finishRecordingAndDismiss()
                    } label: {
                        Label("Finish", systemImage: "microphone.fill")
                            .font(.title2)
                    }
                } else {
                    Button(action: { viewModel.startRecording() }) {
                        Label("Start", systemImage: "microphone")
                            .font(.title2)
                    }
                    .disabled(!viewModel.canStartRecording)
                }
            }
            .animation(.default, value: viewModel.isRecording)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { finishRecordingAndDismiss() }) {
                        Label("Close", systemImage: "checkmark")
                    }
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .background,
                   viewModel.isRecording {
                    finishRecordingAndDismiss()
                }
            }
        }
        .presentationDetents([.fraction(0.3)])
    }
    
    private func finishRecordingAndDismiss() {
        if let recordedURL = viewModel.stopRecording() {
            onRecordingFinished(recordedURL)
        }
        dismiss()
    }
}

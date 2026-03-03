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
    @StateObject private var viewModel = RecorderViewModel()
    
    let onRecordingFinished: (URL) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(viewModel.elapsedTimeText)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                
                Group {
                    if viewModel.isRecording {
                        Button(role: .destructive) {
                            finishRecordingAndDismiss()
                        } label: {
                            Label("Recording", systemImage: "stop.circle")
                        }
                        .keyboardShortcut("S", modifiers: [.command])
                    } else {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Preparing...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.title2)
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
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { dismiss() }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onDisappear { finishRecording() }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.dropblue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .opacity(0.25 * Double(viewModel.micLevel))
            .animation(.smooth, value: viewModel.micLevel)
        )
        .presentationDetents([.fraction(0.3)])
    }
    
    private func finishRecording() {
        if viewModel.isRecording,
           let recordedURL = viewModel.stopRecording() {
            onRecordingFinished(recordedURL)
        }
    }
    
    private func finishRecordingAndDismiss() {
        finishRecording()
        dismiss()
    }
}

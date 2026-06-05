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
                    .padding(.top, 40)
                
                Group {
                    if viewModel.isRecording {
                        Button(role: .destructive) {
                            viewModel.finishRecording()
                            dismiss()
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
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { dismiss() }
            } message: {
                Text(viewModel.errorMessage)
            }
            // MARK: - Events
            .onAppear { viewModel.startRecording() }
            .onDisappear { viewModel.finishRecording() }
            .onReceive(viewModel.$isFinished) { isFinished in
                if isFinished {
                    if let url = viewModel.recordedURL {
                        onRecordingFinished(url)
                    }
                    dismiss()
                }
            }
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
}

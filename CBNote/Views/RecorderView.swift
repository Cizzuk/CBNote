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
    @StateObject private var vm = RecorderViewModel()
    
    let onRecordingFinished: (URL) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(vm.elapsedTimeText)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .padding(.top, 40)
                
                Group {
                    if vm.isRecording {
                        Button(role: .destructive) {
                            vm.finishRecording()
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
            .animation(.default, value: vm.isRecording)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .alert("Error", isPresented: $vm.showError) {
                Button("OK") { dismiss() }
            } message: {
                Text(vm.errorMessage)
            }
            // MARK: - Events
            .onAppear { vm.startRecording() }
            .onDisappear { vm.finishRecording() }
            .onReceive(vm.$isFinished) { isFinished in
                if isFinished {
                    if let url = vm.recordedURL {
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
            .opacity(0.25 * Double(vm.micLevel))
            .animation(.smooth, value: vm.micLevel)
        )
        .presentationDetents([.fraction(0.3)])
        .interactiveDismissDisabled()
    }
}

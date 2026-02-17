//
//  DummyCameraView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

#if !targetEnvironment(macCatalyst)

import AVKit
import SwiftUI

struct DummyCameraView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        DummyCameraPreview(session: viewModel.session)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .opacity(0)
            .frame(width: 0, height: 0)
            .onChange(of: scenePhase) {
                if scenePhase == .background {
                    viewModel.stopSession()
                    DummyCameraManager.shared.close()
                }
            }
            .onAppear {
                viewModel.startSession()
            }
            .onDisappear {
                viewModel.stopSession()
                DummyCameraManager.shared.close()
            }
            .onCameraCaptureEvent(defaultSoundDisabled: true) { _ in }
    }
    
    struct DummyCameraPreview: UIViewRepresentable {
        let session: AVCaptureSession
        
        func makeUIView(context: Context) -> UIView {
            return UIView(frame: .zero)
        }
        
        func updateUIView(_ uiView: UIView, context: Context) { }
    }
}

#else

// MARK: - Mac Catalyst Fall Back

import SwiftUI

struct DummyCameraView: View {
    var body: some View {
        EmptyView()
    }
}

#endif

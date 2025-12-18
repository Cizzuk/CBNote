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
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        DummyCameraPreview(session: viewModel.session)
            .opacity(0)
            .frame(width: 0, height: 0)
            .onAppear {
                viewModel.startSession()
            }
            .onDisappear {
                viewModel.stopSession()
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

#endif

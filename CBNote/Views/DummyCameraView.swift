//
//  DummyCameraView.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import SwiftUI
import AVKit

struct DummyCameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        CameraPreview(session: viewModel.session) { _ in }
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
}

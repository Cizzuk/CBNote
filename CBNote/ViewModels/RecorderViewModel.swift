//
//  RecorderViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/16.
//

import Combine
import SwiftUI
import UIKit

class RecorderViewModel: ObservableObject {
    private let recorder = AudioRecorder()
    private var cancellables = Set<AnyCancellable>()
    
    var onFinish: ((URL) -> Void)? {
        get { recorder.onFinish }
        set { recorder.onFinish = newValue }
    }
    
    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var micLevel: Float = 0.0
    
    @Published var showError = false
    @Published var errorMessage: LocalizedStringResource = ""
    
    var elapsedTimeText: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() {
        recorder.onError = { [weak self] error in
            guard let self = self else { return }
            switch error {
            case .various(let e):
                showErrorMessage("\(e.localizedDescription)")
            case .permissionDenied:
                showErrorMessage("Microphone access denied. Please enable it in Settings.")
            case .unknownAuthorizationStatus:
                showErrorMessage("Unknown microphone authorization status.")
            case .recordingFailed:
                showErrorMessage("Failed to start recording.")
            }
        }
        
        recorder.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        recorder.$elapsedTime
            .receive(on: DispatchQueue.main)
            .assign(to: \.elapsedTime, on: self)
            .store(in: &cancellables)
        
        recorder.$micLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.micLevel, on: self)
            .store(in: &cancellables)
    }
    
    func showErrorMessage(_ message: LocalizedStringResource) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    func startRecording() {
        recorder.startRecording()
    }
    
    func finishRecording() {
        recorder.finishRecording()
    }
}

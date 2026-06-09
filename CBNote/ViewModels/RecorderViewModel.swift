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
    private let recorder = AudioRecorderService()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isFinished = false
    var recordedURL: URL?
    
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
        recorder.onFinish = { [weak self] url in
            DispatchQueue.main.async {
                self?.recordedURL = url
                self?.isFinished = true
            }
        }
        
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
        
        // Observers
        
        recorder.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recording in
                self?.isRecording = recording
            }
            .store(in: &cancellables)
        
        recorder.$elapsedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.elapsedTime = time
            }
            .store(in: &cancellables)
        
        recorder.$micLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.micLevel = level
            }
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

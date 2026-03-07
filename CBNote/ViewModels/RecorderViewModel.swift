//
//  RecorderViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/16.
//

import AVFoundation
import Combine
import SwiftUI

class RecorderViewModel: ObservableObject {
    @Published var shouldDismiss = false
    
    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var micLevel: Float = 0.0
    
    @Published var showError = false
    @Published var errorMessage: LocalizedStringResource = ""
    
    private var audioRecorder: AVAudioRecorder?
    private var timerCancellable: AnyCancellable?
    private var recordingURL: URL?
    
    var elapsedTimeText: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() { startRecording() }
    
    func showErrorMessage(_ message: LocalizedStringResource) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    @MainActor
    func startRecording() {
        Task {
            guard !isRecording else { return }
            
            // Check Permission
            if !(await checkPermission()) {
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
            ]
            
            let sessionOptions: AVAudioSession.CategoryOptions
            #if targetEnvironment(macCatalyst)
            sessionOptions = [.mixWithOthers, .allowBluetoothA2DP]
            #else
            sessionOptions = [.mixWithOthers, .allowBluetoothA2DP, .bluetoothHighQualityRecording]
            #endif
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default, options: sessionOptions)
                    try session.setActive(true)
                    
                    let recorder = try AVAudioRecorder(url: tempURL, settings: settings)
                    recorder.isMeteringEnabled = true
                    
                    guard recorder.record() else {
                        showErrorMessage("Failed to start recording.")
                        return
                    }
                    
                    audioRecorder = recorder
                    recordingURL = tempURL
                    
                    DispatchQueue.main.async {
                        self.elapsedTime = 0
                        self.isRecording = true
                    }
                    
                    startTimer()
                    RecorderActivityManager.start()
                } catch {
                    stopTimer()
                    RecorderActivityManager.endAll()
                    
                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.showErrorMessage("\(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        isRecording = false
        micLevel = 0
        
        audioRecorder?.stop()
        stopTimer()
        RecorderActivityManager.endAll()
        
        guard let finishedURL = recordingURL else { return nil }
        audioRecorder = nil
        recordingURL = nil
        
        DispatchQueue.global(qos: .utility).async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        
        return finishedURL
    }
    
    @MainActor
    func checkPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            showErrorMessage("Microphone access denied. Please enable it in Settings.")
            return false
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted {
                showErrorMessage("Microphone access denied. Please enable it in Settings.")
                return false
            }
        @unknown default:
            showErrorMessage("Unknown microphone authorization status.")
            return false
        }
        
        return true
    }
    
    private func startTimer() {
        stopTimer()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedTime = self.audioRecorder?.currentTime ?? self.elapsedTime

                // Update micLevel
                self.audioRecorder?.updateMeters()
                let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -60
                let minPower: Float = -60
                let level = max(0, min(1, (power - minPower) / abs(minPower)))
                self.micLevel = level
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

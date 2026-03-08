//
//  RecorderViewModel.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/16.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

class RecorderViewModel: ObservableObject {
    @Published var shouldDismiss = false
    
    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var micLevel: Float = 0.0
    
    @Published var showError = false
    @Published var errorMessage: LocalizedStringResource = ""
    
    private var audioRecorder: AVAudioRecorder?
    private var timerCancellable: AnyCancellable?
    private var notificationCancellables = Set<AnyCancellable>()
    private var recordingURL: URL?
    
    var elapsedTimeText: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private static let finishRecordDarwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
        guard let observer else { return }
        let viewModel = Unmanaged<RecorderViewModel>.fromOpaque(observer).takeUnretainedValue()
        
        // Check Flag
        if GroupUserDefaults.bool(forKey: CFNotificationFlags.shouldFinishRecording) {
            DispatchQueue.main.async {
                viewModel.shouldDismiss = true
            }
            GroupUserDefaults.set(false, forKey: CFNotificationFlags.shouldFinishRecording)
        }
    }
    
    init() {
        // Observe Darwin Notification for Finishing Recording from Live Activity
        GroupUserDefaults.set(false, forKey: CFNotificationFlags.shouldFinishRecording)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            RecorderViewModel.finishRecordDarwinCallback,
            CFNotificationName.shouldFinishRecording.rawValue,
            nil,
            .deliverImmediately
        )
        
        // Observe AVAudioSession Interruptions
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue),
                      type == .began
                else { return }

                DispatchQueue.main.async {
                    self?.shouldDismiss = true
                }
            }
            .store(in: &notificationCancellables)

        // Observe App Termination
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.shouldDismiss = true
                }
            }
            .store(in: &notificationCancellables)
        
        startRecording()
    }

    deinit {
        // Remove All Darwin Notification Observers
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )
    }
    
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

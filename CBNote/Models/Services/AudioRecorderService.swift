//
//  AudioRecorderService.swift
//  CBNote
//
//  Created by Cizzuk on 2026/06/05.
//

import AVFoundation
import Combine
import UIKit

class AudioRecorderService: ObservableObject {
    enum RecordError: Error {
        case various(Error)
        case permissionDenied
        case unknownAuthorizationStatus
        case recordingFailed
    }
    
    var onFinish: ((URL) -> Void)?
    var onError: ((RecordError) -> Void)?
    
    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var micLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var timerCancellable: AnyCancellable?
    private var notificationCancellables = Set<AnyCancellable>()
    private var recordingURL: URL?
    
    private static let finishRecordDarwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
        guard let observer else { return }
        let instance = Unmanaged<AudioRecorderService>.fromOpaque(observer).takeUnretainedValue()
        
        // Check Flag
        if GroupUserDefaults.bool(forKey: CFNotificationFlags.shouldFinishRecording) {
            DispatchQueue.main.async {
                instance.finishRecording()
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
            AudioRecorderService.finishRecordDarwinCallback,
            CFNotificationName.shouldFinishRecording.rawValue,
            nil,
            .deliverImmediately
        )
        
        // Observe AVAudioSession Interruptions
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue),
                      type == .began
                else { return }
                
                self?.finishRecording()
            }
            .store(in: &notificationCancellables)
        
        // Observe App Termination
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.finishRecording()
            }
            .store(in: &notificationCancellables)
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
                        onError?(RecordError.recordingFailed)
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
                        self.onError?(RecordError.various(error))
                    }
                }
            }
        }
    }
    
    func finishRecording() {
        guard isRecording else { return }
        isRecording = false
        micLevel = 0
        
        audioRecorder?.stop()
        stopTimer()
        RecorderActivityManager.endAll()
        
        guard let finishedURL = recordingURL else { return }
        audioRecorder = nil
        recordingURL = nil
        
        DispatchQueue.global(qos: .utility).async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        
        onFinish?(finishedURL)
    }
    
    @MainActor
    func checkPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            onError?(RecordError.permissionDenied)
            return false
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted {
                onError?(RecordError.permissionDenied)
                return false
            }
        @unknown default:
            onError?(RecordError.unknownAuthorizationStatus)
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

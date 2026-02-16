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
	@Published var canStartRecording = false
	@Published var isRecording = false
	@Published var elapsedTime: TimeInterval = 0
    
	private var audioRecorder: AVAudioRecorder?
	private var timerCancellable: AnyCancellable?
	private var recordingURL: URL?
    
	var elapsedTimeText: String {
		let totalSeconds = Int(elapsedTime)
		let minutes = totalSeconds / 60
		let seconds = totalSeconds % 60
		return String(format: "%02d:%02d", minutes, seconds)
	}
    
    init() {
        preparePermission()
    }
    
	func preparePermission() {
        switch AVAudioApplication.shared.recordPermission {
		case .granted:
			canStartRecording = true
		case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
				DispatchQueue.main.async {
					self.canStartRecording = granted
				}
			}
		case .denied:
			canStartRecording = false
		@unknown default:
			canStartRecording = false
		}
	}
    
	func startRecording() {
		guard canStartRecording, !isRecording else { return }
        
		let tempURL = FileManager.default.temporaryDirectory
			.appendingPathComponent("\(UUID().uuidString).m4a")
        
		let settings: [String: Any] = [
			AVFormatIDKey: kAudioFormatMPEG4AAC,
			AVSampleRateKey: 44_100,
			AVNumberOfChannelsKey: 1,
			AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
		]
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .default, options: [.duckOthers])
                try session.setActive(true)
                
                let recorder = try AVAudioRecorder(url: tempURL, settings: settings)
                guard recorder.record() else { return }
                
                audioRecorder = recorder
                recordingURL = tempURL
                
                DispatchQueue.main.async {
                    self.elapsedTime = 0
                    self.isRecording = true
                }
                
                startTimer()
            } catch {
                stopTimer()
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
	}
    
	func stopRecording() -> URL? {
		guard isRecording else { return nil }
        
		audioRecorder?.stop()
		stopTimer()
		isRecording = false
        
		let finishedURL = recordingURL
		audioRecorder = nil
		recordingURL = nil
        
		try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
		return finishedURL
	}
    
	private func startTimer() {
		stopTimer()
		timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
			.autoconnect()
			.sink { [weak self] _ in
				guard let self = self else { return }
				self.elapsedTime = self.audioRecorder?.currentTime ?? self.elapsedTime
			}
	}
    
	private func stopTimer() {
		timerCancellable?.cancel()
		timerCancellable = nil
	}
}

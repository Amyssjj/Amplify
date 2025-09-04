//
//  AudioRecordingService.swift
//  Amplify
//
//  Service for handling audio recording with AVFoundation
//

import Foundation
import AVFoundation

@MainActor
class AudioRecordingService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPrepared = false
    @Published var currentRecordingDuration: TimeInterval = 0
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    // MARK: - Configuration
    var maxRecordingDuration: TimeInterval = 60.0 // 60 seconds max
    var currentRecordingURL: URL?
    
    // MARK: - Testing Support
    var mockPermissionStatus: MicrophonePermissionStatus?
    
    // MARK: - Public Methods
    
    func requestMicrophonePermission() async -> MicrophonePermissionStatus {
        if let mockStatus = mockPermissionStatus {
            return mockStatus
        }
        
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }
    }
    
    func prepareForRecording() async -> Result<Void, AudioRecordingError> {
        let permission = await requestMicrophonePermission()
        
        guard permission == .authorized else {
            return .failure(.permissionDenied)
        }
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            // Create recording URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
            currentRecordingURL = audioFilename
            
            // Create audio recorder
            let settings = getRecordingSettings()
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            isPrepared = true
            return .success(())
            
        } catch {
            return .failure(.audioSessionSetupFailed)
        }
    }
    
    func startRecording() -> Result<Void, AudioRecordingError> {
        guard isPrepared, let recorder = audioRecorder else {
            return .failure(.notPrepared)
        }
        
        guard !isRecording else {
            return .failure(.alreadyRecording)
        }
        
        let success = recorder.record()
        
        if success {
            isRecording = true
            recordingStartTime = Date()
            startRecordingTimer()
            return .success(())
        } else {
            return .failure(.recordingStartFailed)
        }
    }
    
    func stopRecording() -> Result<AudioRecordingData, AudioRecordingError> {
        guard isRecording, let recorder = audioRecorder else {
            return .failure(.notRecording)
        }
        
        recorder.stop()
        stopRecordingTimer()
        isRecording = false
        
        let duration = currentRecordingDuration
        
        guard let url = currentRecordingURL else {
            return .failure(.noRecordingURL)
        }
        
        let recordingData = AudioRecordingData(
            url: url,
            duration: duration,
            createdAt: Date()
        )
        
        return .success(recordingData)
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        stopRecordingTimer()
        isRecording = false
        
        // Delete the recording file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Deactivate audio session to prevent lag on next recording attempt
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session during cancel: \(error)")
        }
        
        audioRecorder = nil
        currentRecordingURL = nil
        currentRecordingDuration = 0
        isPrepared = false
    }
    
    func cleanup() {
        audioRecorder?.stop()
        stopRecordingTimer()
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
        
        audioRecorder = nil
        currentRecordingURL = nil
        isPrepared = false
        isRecording = false
        currentRecordingDuration = 0
    }
    
    func getRecordingSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    // MARK: - Private Methods
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        
        currentRecordingDuration = Date().timeIntervalSince(startTime)
        
        // Auto-stop when max duration reached
        if currentRecordingDuration >= maxRecordingDuration {
            _ = stopRecording()
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
            stopRecordingTimer()
            
            if !flag {
                // Recording failed
                currentRecordingURL = nil
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            isRecording = false
            stopRecordingTimer()
        }
        print("Audio recording encode error: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// MARK: - Supporting Types

enum MicrophonePermissionStatus {
    case authorized
    case denied
    case undetermined
}

enum AudioRecordingError: Error, Equatable {
    case permissionDenied
    case audioSessionSetupFailed
    case notPrepared
    case alreadyRecording
    case recordingStartFailed
    case notRecording
    case noRecordingURL
}

struct AudioRecordingData {
    let url: URL
    let duration: TimeInterval
    let createdAt: Date
}
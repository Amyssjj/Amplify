//
//  SpeechRecognitionService.swift
//  Amplify
//
//  Service for handling live speech recognition and audio file transcription
//

import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognitionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecognizing = false
    @Published var currentTranscript = ""
    @Published var recognitionConfidence: Float = 0.0
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Callbacks
    var onTranscriptUpdate: ((String) -> Void)?
    var onConfidenceUpdate: ((Float) -> Void)?
    
    // MARK: - Testing Support
    var mockPermissionStatus: SpeechRecognitionPermissionStatus?
    var mockIsAvailable: Bool?
    
    // MARK: - Public Methods
    
    func requestSpeechRecognitionPermission() async -> SpeechRecognitionPermissionStatus {
        if let mockStatus = mockPermissionStatus {
            return mockStatus
        }
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    let permissionStatus = Self.mapSpeechRecognitionAuthStatus(status)
                    continuation.resume(returning: permissionStatus)
                }
            }
        }
    }
    
    func isAvailableForRecognition() -> Bool {
        if let mockAvailable = mockIsAvailable {
            return mockAvailable
        }
        
        return speechRecognizer?.isAvailable ?? false
    }
    
    func startLiveRecognition(
        onTranscriptUpdate: @escaping (String) -> Void
    ) async -> Result<Void, SpeechRecognitionError> {
        
        // Check permission
        let permission = await requestSpeechRecognitionPermission()
        guard permission == .authorized else {
            return .failure(.permissionDenied)
        }
        
        // Check availability
        guard isAvailableForRecognition() else {
            return .failure(.recognitionUnavailable)
        }
        
        // Stop any existing recognition
        if isRecognizing {
            stopLiveRecognition()
        }
        
        self.onTranscriptUpdate = onTranscriptUpdate
        
        do {
            try startAudioEngine()
            isRecognizing = true
            return .success(())
        } catch {
            return .failure(.audioEngineStartFailed)
        }
    }
    
    func stopLiveRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecognizing = false
        currentTranscript = ""
        recognitionConfidence = 0.0
    }
    
    func recognizeAudioFile(url: URL) async -> Result<String, SpeechRecognitionError> {
        let permission = await requestSpeechRecognitionPermission()
        guard permission == .authorized else {
            return .failure(.permissionDenied)
        }
        
        guard let recognizer = speechRecognizer else {
            return .failure(.recognitionUnavailable)
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return await withCheckedContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                DispatchQueue.main.async {
                    if error != nil {
                        continuation.resume(returning: .failure(.recognitionFailed))
                    } else if let result = result, result.isFinal {
                        continuation.resume(returning: .success(result.bestTranscription.formattedString))
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startAudioEngine() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        guard let speechRecognizer = speechRecognizer else {
            throw SpeechRecognitionError.recognitionUnavailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let result = result {
                    let transcript = result.bestTranscription.formattedString
                    self.currentTranscript = transcript
                    self.onTranscriptUpdate?(transcript)
                    
                    // Update confidence
                    if let segment = result.bestTranscription.segments.last {
                        self.recognitionConfidence = segment.confidence
                        self.onConfidenceUpdate?(segment.confidence)
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopLiveRecognition()
                }
            }
        }
    }
    
    // MARK: - Testing Support Methods
    
    func simulateTranscriptUpdate(_ transcript: String) {
        currentTranscript = transcript
        onTranscriptUpdate?(transcript)
    }
    
    func simulateConfidenceUpdate(_ confidence: Float) {
        recognitionConfidence = confidence
        onConfidenceUpdate?(confidence)
    }
    
    // MARK: - Static Methods
    
    static func mapSpeechRecognitionAuthStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> SpeechRecognitionPermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

// MARK: - Supporting Types

enum SpeechRecognitionPermissionStatus {
    case authorized
    case denied
    case restricted
    case notDetermined
}

enum SpeechRecognitionError: Error, Equatable {
    case permissionDenied
    case recognitionUnavailable
    case audioEngineStartFailed
    case requestCreationFailed
    case recognitionFailed
}
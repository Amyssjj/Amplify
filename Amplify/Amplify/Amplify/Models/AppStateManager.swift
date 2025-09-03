//
//  AppStateManager.swift
//  Amplify
//
//  Central state management for the Amplify app
//

import Foundation
import SwiftUI

@MainActor
class AppStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    // Screen Navigation
    @Published var currentScreen: AppScreen = .home
    
    // Recording State
    @Published var isRecording = false
    @Published var recordingStartTime: Date?
    
    // Processing State
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    // Current Data
    @Published var currentPhoto: PhotoData?
    @Published var currentRecording: Recording?
    
    // Permission States
    @Published var photoPermissionStatus: PhotoLibraryPermissionStatus = .notDetermined
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .undetermined
    @Published var speechPermissionStatus: SpeechRecognitionPermissionStatus = .notDetermined
    
    // Error Handling
    @Published var currentError: AppError?
    @Published var showingError = false
    
    // MARK: - Computed Properties
    
    var hasAllPermissions: Bool {
        return photoPermissionStatus == .authorized &&
               microphonePermissionStatus == .authorized &&
               speechPermissionStatus == .authorized
    }
    
    var hasAnyPermissionDenied: Bool {
        return photoPermissionStatus == .denied ||
               microphonePermissionStatus == .denied ||
               speechPermissionStatus == .denied
    }
    
    var canRecord: Bool {
        return microphonePermissionStatus == .authorized &&
               speechPermissionStatus == .authorized &&
               !isRecording
    }
    
    var currentRecordingDuration: TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Public Methods
    
    func transitionToRecording(with photo: PhotoData) {
        print("📥 DEBUG: AppStateManager.transitionToRecording called with photo")
        currentPhoto = photo
        currentScreen = .recording
        print("✅ DEBUG: AppState.currentPhoto set, screen = .recording")
    }
    
    func startRecording() {
        isRecording = true
        recordingStartTime = Date()
    }
    
    func stopRecording(with recording: Recording) {
        isRecording = false
        recordingStartTime = nil
        currentRecording = recording
        currentScreen = .processing
        isProcessing = true
    }
    
    func transitionToResults(with insights: [AIInsight]) async {
        guard let recording = currentRecording else { return }
        
        // Add insights to recording
        for insight in insights {
            recording.addInsight(insight)
        }
        
        isProcessing = false
        currentScreen = .results
    }
    
    func returnToHome() {
        currentScreen = .home
        currentRecording = nil
        currentPhoto = nil
        isRecording = false
        isProcessing = false
        recordingStartTime = nil
        processingProgress = 0.0
    }
    
    // MARK: - Permission Management
    
    func updatePhotoPermissionStatus(_ status: PhotoLibraryPermissionStatus) {
        photoPermissionStatus = status
    }
    
    func updateMicrophonePermissionStatus(_ status: MicrophonePermissionStatus) {
        microphonePermissionStatus = status
    }
    
    func updateSpeechPermissionStatus(_ status: SpeechRecognitionPermissionStatus) {
        speechPermissionStatus = status
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: AppError) {
        currentError = error
        showingError = true
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
    
    // MARK: - Processing Management
    
    func setProcessing(_ processing: Bool, progress: Double = 0.0) {
        isProcessing = processing
        processingProgress = progress
    }
}

// MARK: - Supporting Types

enum AppScreen: String, CaseIterable {
    case home
    case recording
    case processing
    case results
    
    var title: String {
        switch self {
        case .home:
            return "Amplify"
        case .recording:
            return "Recording"
        case .processing:
            return "Cooking Your Story"
        case .results:
            return "Your Enhanced Story"
        }
    }
}

enum AppError: Error, Equatable {
    case photoLibraryAccessDenied
    case microphoneAccessDenied
    case speechRecognitionAccessDenied
    case recordingFailed
    case audioProcessingFailed
    case aiProcessingFailed
    case networkError
    case unknown
    
    var title: String {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo Access Needed"
        case .microphoneAccessDenied:
            return "Microphone Access Needed"
        case .speechRecognitionAccessDenied:
            return "Speech Recognition Access Needed"
        case .recordingFailed:
            return "Recording Failed"
        case .audioProcessingFailed:
            return "Audio Processing Failed"
        case .aiProcessingFailed:
            return "AI Processing Failed"
        case .networkError:
            return "Network Error"
        case .unknown:
            return "Unknown Error"
        }
    }
    
    var message: String {
        switch self {
        case .photoLibraryAccessDenied:
            return "Please allow access to your photo library to select story prompts."
        case .microphoneAccessDenied:
            return "Please allow microphone access to record your stories."
        case .speechRecognitionAccessDenied:
            return "Please allow speech recognition to transcribe your stories."
        case .recordingFailed:
            return "Unable to record audio. Please try again."
        case .audioProcessingFailed:
            return "Unable to process the audio recording. Please try again."
        case .aiProcessingFailed:
            return "Unable to enhance your story. Please check your connection and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}
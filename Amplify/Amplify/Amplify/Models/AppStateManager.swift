//
//  AppStateManager.swift
//  Amplify
//
//  Central state management for the Amplify app
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class AppStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    // Screen Navigation
    @Published var currentScreen: AppScreen = .home
    
    // Authentication State
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var currentUser: User?
    
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
    
    // MARK: - API Integration
    
    private(set) var enhancementService: EnhancementService
    private(set) var audioPlayerService: AudioPlayerService
    
    // MARK: - Initialization
    
    init() {
        // Initialize enhancement service based on API configuration
        // Handle circular dependency by creating APIClient first, then AuthService with APIClient
        let tempAuthService = AuthenticationService() // Temporary for APIClient creation
        let apiClient = APIClient(
            baseURL: APIConfiguration.baseURL,
            authService: tempAuthService
        )
        
        // Create the final AuthenticationService with the APIClient
        let sharedAuthService = AuthenticationService(apiClient: apiClient)
        
        self.enhancementService = EnhancementService(
            apiClient: apiClient,
            authService: sharedAuthService,
            mapperService: ModelMapperService(),
            networkManager: NetworkManager()
        )
        
        // Initialize audio player service
        self.audioPlayerService = AudioPlayerService(enhancementService: enhancementService)
        
        #if DEBUG
        if APIConfiguration.FeatureFlags.enableDebugLogging {
            APIConfiguration.printConfiguration()
        }
        #endif
    }
    
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
    
    var isAuthenticated: Bool {
        return enhancementService.isAuthenticated
    }
    
    var requiresAuthentication: Bool {
        return !isAuthenticated && currentScreen != .home
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
        currentPhoto = photo
        currentScreen = .recording
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
    
    // MARK: - Authentication Methods
    
    func signInWithGoogle(_ idToken: String) async throws {
        do {
            let user = try await enhancementService.signInWithGoogle(idToken: idToken)
            currentUser = user
            authenticationState = .authenticated(user)
        } catch {
            handleError(.authenticationFailed)
            throw error
        }
    }
    
    func signOut() async {
        await enhancementService.signOut()
        currentUser = nil
        authenticationState = .unauthenticated
        
        // Return to home if user was in authenticated screens
        if currentScreen != .home {
            returnToHome()
        }
    }
    
    // MARK: - Enhancement Methods
    
    func enhanceRecording(_ recording: Recording) async throws {
        guard let photo = currentPhoto else {
            throw AppError.photoDataMissing
        }
        
        guard let photoData = await getPhotoData(for: photo) else {
            throw AppError.photoProcessingFailed
        }
        
        do {
            let enhanced = try await enhancementService.enhanceRecording(
                recording,
                photoData: photoData
            )
            
            // Update the current recording with enhanced data
            currentRecording = enhanced
            
            // Transition to results immediately - don't wait for audio
            await transitionToResults(with: enhanced.insights)
            
            // Preload audio in background after transitioning to results
            if let enhancementId = enhanced.enhancementId {
                Task {
                    print("🔵 Background preloading audio for enhancement: \(enhancementId)")
                    do {
                        let audioData = try await enhancementService.getEnhancementAudio(
                            for: enhanced, 
                            enhancementId: enhancementId
                        )
                        // Setup audio player with the fetched data
                        try await audioPlayerService.preloadAudio(with: audioData, enhancementId: enhancementId)
                        print("✅ Audio preloaded successfully in background")
                    } catch {
                        print("🔴 Failed to preload audio: \(error)")
                        // Audio loading failure doesn't affect user experience
                    }
                }
            }
            
        } catch {
            print("🔴 Enhancement failed with error: \(error)")
            print("🔴 Error type: \(type(of: error))")
            if let apiError = error as? APIError {
                print("🔴 API Error details: \(apiError)")
            }
            handleError(.enhancementFailed)
            throw error
        }
    }
    
    private func getPhotoData(for photo: PhotoData) async -> Data? {
        // Convert UIImage to JPEG data for API upload
        return photo.image.jpegData(compressionQuality: 0.8)
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
    case authenticationFailed
    case enhancementFailed
    case photoDataMissing
    case photoProcessingFailed
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
        case .authenticationFailed:
            return "Authentication Failed"
        case .enhancementFailed:
            return "Enhancement Failed"
        case .photoDataMissing:
            return "Photo Missing"
        case .photoProcessingFailed:
            return "Photo Processing Failed"
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
        case .authenticationFailed:
            return "Unable to sign in. Please try again."
        case .enhancementFailed:
            return "Unable to enhance your story. Please check your connection and try again."
        case .photoDataMissing:
            return "Photo data is missing. Please select a photo again."
        case .photoProcessingFailed:
            return "Unable to process the selected photo. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}
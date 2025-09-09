//
//  MockServices.swift
//  AmplifyAPITests
//
//  Mock implementations for testing API client and authentication
//

import Foundation
import UIKit
import Photos

@testable import Amplify

// MARK: - Mock Authentication Service

@MainActor
class MockAuthenticationService: AuthenticationServiceProtocol {
    
    // MARK: - Mock Properties
    var mockToken: String?
    var mockAuthState: AuthenticationState = .unauthenticated
    var mockUser: User?
    
    // Test tracking properties
    var refreshTokenCalled = false
    var refreshTokenResult = false
    var signOutCalled = false
    var signInCalled = false
    
    // MARK: - Protocol Implementation
    
    var authenticationState: AuthenticationState {
        return mockAuthState
    }
    
    var currentUser: User? {
        return mockUser
    }
    
    var currentToken: String? {
        return mockToken
    }
    
    func signInWithGoogle(idToken: String) async throws -> AuthResponse {
        signInCalled = true
        
        let user = AuthResponseUser(
            userId: "mock_user_123",
            email: "test@example.com",
            name: "Mock User",
            picture: nil
        )
        
        let response = AuthResponse(
            accessToken: "mock_jwt_token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: user
        )
        
        mockToken = response.accessToken
        mockUser = User(from: user)
        mockAuthState = .authenticated(mockUser!)
        
        return response
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        refreshTokenCalled = true
        return refreshTokenResult
    }
    
    func signOut() async {
        signOutCalled = true
        mockToken = nil
        mockUser = nil
        mockAuthState = .unauthenticated
    }
    
    func isTokenValid() -> Bool {
        return mockToken != nil
    }
}

// MARK: - URLSession Protocol
// Note: URLSessionProtocol is defined in APIClient.swift in the main app module

// MARK: - Mock URL Session

class MockURLSession: URLSessionProtocol {
    
    // MARK: - Mock Data
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    // Response queue for multiple requests
    var responseQueue: [(Data, URLResponse)] = []
    private var responseIndex = 0
    
    // Test tracking
    var lastRequest: URLRequest?
    var requestCount = 0
    var shouldThrowError = false
    
    // MARK: - URLSession Override
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        requestCount += 1
        
        if shouldThrowError, let error = mockError {
            throw error
        }
        
        // Use response queue if available
        if !responseQueue.isEmpty && responseIndex < responseQueue.count {
            let response = responseQueue[responseIndex]
            responseIndex += 1
            return response
        }
        
        // Use single mock response
        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        responseQueue.removeAll()
        responseIndex = 0
        lastRequest = nil
        requestCount = 0
        shouldThrowError = false
    }
}

// MARK: - Mock Token Storage

class MockTokenStorage: TokenStorage {
    
    private var storedAccessToken: String?
    private var storedExpiration: Date?
    private var storedUser: User?
    
    // Test tracking
    var storeTokensCalled = false
    var clearTokensCalled = false
    
    func storeTokens(accessToken: String, expiration: Date, user: User) async throws {
        storeTokensCalled = true
        storedAccessToken = accessToken
        storedExpiration = expiration
        storedUser = user
    }
    
    func getAccessToken() async -> String? {
        return storedAccessToken
    }
    
    func getTokenExpiration() async -> Date? {
        return storedExpiration
    }
    
    func getUser() async -> User? {
        return storedUser
    }
    
    func clearTokens() async {
        clearTokensCalled = true
        storedAccessToken = nil
        storedExpiration = nil
        storedUser = nil
    }
    
    // Test helpers
    func reset() {
        storedAccessToken = nil
        storedExpiration = nil
        storedUser = nil
        storeTokensCalled = false
        clearTokensCalled = false
    }
}

// MARK: - Mock API Client

@MainActor
class MockAPIClient: APIClientProtocol {
    
    // MARK: - Mock Responses
    var mockAuthResponse: AuthResponse?
    var mockEnhancementResponse: EnhancementTextResponse?
    var mockAudioResponse: EnhancementAudioResponse?
    var mockHistoryResponse: GetEnhancements200Response?
    var mockDetailsResponse: EnhancementDetails?
    var mockHealthResponse: GetHealth200Response?
    
    // MARK: - Mock Errors
    var shouldThrowError = false
    var mockError: Error = APIError.networkError(URLError(.notConnectedToInternet))
    
    // MARK: - Test Tracking
    var authenticateCalled = false
    var createEnhancementCalled = false
    var getAudioCalled = false
    var getHistoryCalled = false
    var getDetailsCalled = false
    var getHealthCalled = false
    
    var lastEnhancementRequest: EnhancementRequest?
    var lastGoogleToken: String?
    var lastEnhancementId: String?
    var lastHistoryParams: (limit: Int, offset: Int)?
    
    // MARK: - Protocol Implementation
    
    func authenticate(googleToken: String) async throws -> AuthResponse {
        authenticateCalled = true
        lastGoogleToken = googleToken
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockAuthResponse ?? AuthResponse(
            accessToken: "mock_token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(
                userId: "mock_user",
                email: "mock@example.com",
                name: "Mock User",
                picture: nil
            )
        )
    }
    
    func createEnhancement(_ request: EnhancementRequest) async throws -> EnhancementTextResponse {
        createEnhancementCalled = true
        lastEnhancementRequest = request
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockEnhancementResponse ?? EnhancementTextResponse(
            enhancementId: "mock_enh_123",
            enhancedTranscript: "Mock enhanced story",
            insights: ["framework": "Mock insight"]
        )
    }
    
    func getEnhancementAudio(id: String) async throws -> EnhancementAudioResponse {
        getAudioCalled = true
        lastEnhancementId = id
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockAudioResponse ?? EnhancementAudioResponse(
            audioBase64: "mock_audio_data".data(using: .utf8)!,
            audioFormat: .mp3
        )
    }
    
    func getEnhancementHistory(limit: Int, offset: Int) async throws -> GetEnhancements200Response {
        getHistoryCalled = true
        lastHistoryParams = (limit, offset)
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockHistoryResponse ?? GetEnhancements200Response(
            total: 0,
            items: []
        )
    }
    
    func getEnhancementDetails(id: String) async throws -> EnhancementDetails {
        getDetailsCalled = true
        lastEnhancementId = id
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockDetailsResponse ?? EnhancementDetails(
            enhancementId: "mock_details_id",
            createdAt: Date(),
            originalTranscript: "Mock original",
            enhancedTranscript: "Mock enhanced",
            insights: [:],
            audioStatus: .notGenerated,
            photoBase64: nil
        )
    }
    
    func getHealth() async throws -> GetHealth200Response {
        getHealthCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockHealthResponse ?? GetHealth200Response(
            status: "healthy",
            timestamp: Date()
        )
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        mockAuthResponse = nil
        mockEnhancementResponse = nil
        mockAudioResponse = nil
        mockHistoryResponse = nil
        mockDetailsResponse = nil
        mockHealthResponse = nil
        
        shouldThrowError = false
        mockError = APIError.networkError(URLError(.notConnectedToInternet))
        
        authenticateCalled = false
        createEnhancementCalled = false
        getAudioCalled = false
        getHistoryCalled = false
        getDetailsCalled = false
        getHealthCalled = false
        
        lastEnhancementRequest = nil
        lastGoogleToken = nil
        lastEnhancementId = nil
        lastHistoryParams = nil
    }
}

// MARK: - Mock Network Manager

@MainActor
class MockNetworkManager: NetworkManagerProtocol {
    
    // MARK: - Mock Properties
    var mockIsConnected = true
    var mockResponse: Any?
    var mockError: Error?
    
    // Test tracking
    var performRequestCalled = false
    var lastRequest: Any?
    
    var isConnected: Bool {
        return mockIsConnected
    }
    
    func startMonitoring() {
        // Mock implementation
    }
    
    func stopMonitoring() {
        // Mock implementation
    }
    
    func performRequest<T: Codable>(_ request: NetworkRequest<T>) async throws -> T {
        performRequestCalled = true
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        if let response = mockResponse as? T {
            return response
        } else {
            throw NetworkError.invalidResponse("Mock response type mismatch")
        }
    }
    
    func reset() {
        mockIsConnected = true
        mockResponse = nil
        mockError = nil
        performRequestCalled = false
        lastRequest = nil
    }
}

// MARK: - Mock AI Enhancement Service

@MainActor
class MockAIEnhancementService: AIEnhancementServiceProtocol {
    
    // MARK: - Mock Properties
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    // Mock responses
    var mockStoryEnhancement: StoryEnhancement?
    var mockInsights: [AIInsight] = []
    var mockStructureAnalysis: StoryStructureAnalysis?
    var mockHighStakeWords: HighStakeWordsDetection?
    var mockError: AIEnhancementError?
    
    // Test tracking
    var enhanceStoryCalled = false
    var generateInsightsCalled = false
    var analyzeStoryStructureCalled = false
    var detectHighStakeWordsCalled = false
    
    func enhanceStory(transcript: String, duration: TimeInterval) async -> Result<StoryEnhancement, AIEnhancementError> {
        enhanceStoryCalled = true
        
        if let error = mockError {
            return .failure(error)
        }
        
        if let enhancement = mockStoryEnhancement {
            return .success(enhancement)
        }
        
        return .success(StoryEnhancement(
            enhancedTranscript: "Enhanced: \(transcript)",
            insights: [],
            wordHighlights: []
        ))
    }
    
    func generateInsights(transcript: String) async -> Result<[AIInsight], AIEnhancementError> {
        generateInsightsCalled = true
        
        if let error = mockError {
            return .failure(error)
        }
        
        return .success(mockInsights)
    }
    
    func analyzeStoryStructure(transcript: String) async -> Result<StoryStructureAnalysis, AIEnhancementError> {
        analyzeStoryStructureCalled = true
        
        if let error = mockError {
            return .failure(error)
        }
        
        if let analysis = mockStructureAnalysis {
            return .success(analysis)
        }
        
        return .success(StoryStructureAnalysis(
            frameworkDetected: "Three Act Structure",
            hasClearBeginning: true,
            hasClearMiddle: true,
            hasClearEnd: true,
            emotionalArc: "Rising action to climax",
            pacingScore: 0.8
        ))
    }
    
    func detectHighStakeWords(transcript: String) async -> Result<HighStakeWordsDetection, AIEnhancementError> {
        detectHighStakeWordsCalled = true
        
        if let error = mockError {
            return .failure(error)
        }
        
        if let detection = mockHighStakeWords {
            return .success(detection)
        }
        
        return .success(HighStakeWordsDetection(
            words: ["important", "crucial"],
            emotionalIntensity: 0.8
        ))
    }
    
    func reset() {
        isProcessing = false
        processingProgress = 0.0
        mockStoryEnhancement = nil
        mockInsights = []
        mockStructureAnalysis = nil
        mockHighStakeWords = nil
        mockError = nil
        enhanceStoryCalled = false
        generateInsightsCalled = false
        analyzeStoryStructureCalled = false
        detectHighStakeWordsCalled = false
    }
}

// MARK: - Mock Audio Recording Service

@MainActor
class MockAudioRecordingService: AudioRecordingServiceProtocol {
    
    // MARK: - Mock Properties
    @Published var isRecording = false
    @Published var isPrepared = false
    @Published var currentRecordingDuration: TimeInterval = 0
    var maxRecordingDuration: TimeInterval = 60.0
    var currentRecordingURL: URL?
    
    // Mock responses
    var mockPermissionStatus: MicrophonePermissionStatus = .authorized
    var mockPreparationResult: Result<Void, AudioRecordingError> = .success(())
    var mockStartResult: Result<Void, AudioRecordingError> = .success(())
    var mockStopResult: Result<AudioRecordingData, AudioRecordingError> = .success(AudioRecordingData(
        url: URL(fileURLWithPath: "/mock/path"),
        duration: 10.0,
        createdAt: Date()
    ))
    
    // Test tracking
    var requestPermissionCalled = false
    var prepareForRecordingCalled = false
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var cancelRecordingCalled = false
    
    func requestMicrophonePermission() async -> MicrophonePermissionStatus {
        requestPermissionCalled = true
        return mockPermissionStatus
    }
    
    func prepareForRecording() async -> Result<Void, AudioRecordingError> {
        prepareForRecordingCalled = true
        return mockPreparationResult
    }
    
    func startRecording() -> Result<Void, AudioRecordingError> {
        startRecordingCalled = true
        isRecording = true
        return mockStartResult
    }
    
    func stopRecording() -> Result<AudioRecordingData, AudioRecordingError> {
        stopRecordingCalled = true
        isRecording = false
        return mockStopResult
    }
    
    func cancelRecording() {
        cancelRecordingCalled = true
        isRecording = false
    }
    
    func reset() {
        isRecording = false
        isPrepared = false
        currentRecordingDuration = 0
        maxRecordingDuration = 60.0
        currentRecordingURL = nil
        mockPermissionStatus = .authorized
        requestPermissionCalled = false
        prepareForRecordingCalled = false
        startRecordingCalled = false
        stopRecordingCalled = false
        cancelRecordingCalled = false
    }
}

// MARK: - Mock Photo Library Service

@MainActor
class MockPhotoLibraryService: PhotoLibraryServiceProtocol {
    
    // Mock responses
    var mockPermissionStatus: PhotoLibraryPermissionStatus = .authorized
    var mockFavoritesResult: Result<PHAssetCollection, PhotoLibraryError> = .failure(.permissionDenied)
    var mockPhotoResult: Result<PhotoData, PhotoLibraryError> = .success(PhotoData(
        image: UIImage(systemName: "photo")!,
        identifier: "mock-photo",
        isFromUserLibrary: false
    ))
    
    // Test tracking
    var requestPermissionCalled = false
    var fetchFavoritesAlbumCalled = false
    var getRandomPhotoFromFavoritesCalled = false
    var getFallbackPhotoCalled = false
    
    func requestPhotoLibraryPermission() async -> PhotoLibraryPermissionStatus {
        requestPermissionCalled = true
        return mockPermissionStatus
    }
    
    func fetchFavoritesAlbum() async -> Result<PHAssetCollection, PhotoLibraryError> {
        fetchFavoritesAlbumCalled = true
        return mockFavoritesResult
    }
    
    func getRandomPhotoFromFavorites() async -> Result<PhotoData, PhotoLibraryError> {
        getRandomPhotoFromFavoritesCalled = true
        return mockPhotoResult
    }
    
    func getFallbackPhoto() -> PhotoData {
        getFallbackPhotoCalled = true
        return PhotoData(
            image: UIImage(systemName: "photo.fill")!,
            identifier: "fallback-photo",
            isFromUserLibrary: false
        )
    }
    
    func reset() {
        mockPermissionStatus = .authorized
        requestPermissionCalled = false
        fetchFavoritesAlbumCalled = false
        getRandomPhotoFromFavoritesCalled = false
        getFallbackPhotoCalled = false
    }
}

// MARK: - Mock Speech Recognition Service

@MainActor 
class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol {
    
    // MARK: - Mock Properties
    @Published var isRecognizing = false
    @Published var currentTranscript = ""
    @Published var recognitionConfidence: Float = 0.0
    var onTranscriptUpdate: ((String) -> Void)?
    var onConfidenceUpdate: ((Float) -> Void)?
    
    // Mock responses
    var mockPermissionStatus: SpeechRecognitionPermissionStatus = .authorized
    var mockRecognitionResult: Result<String, SpeechRecognitionError> = .success("Mock transcript")
    var shouldThrowOnStart = false
    
    // Test tracking
    var requestPermissionCalled = false
    var startLiveRecognitionCalled = false
    var stopLiveRecognitionCalled = false
    var recognizeAudioFileCalled = false
    var lastAudioURL: URL?
    
    func requestSpeechRecognitionPermission() async -> SpeechRecognitionPermissionStatus {
        requestPermissionCalled = true
        return mockPermissionStatus
    }
    
    func startLiveRecognition(onTranscriptUpdate: @escaping (String) -> Void) async -> Result<Void, SpeechRecognitionError> {
        startLiveRecognitionCalled = true
        if shouldThrowOnStart {
            return .failure(.recognitionFailed)
        }
        isRecognizing = true
        return .success(())
    }
    
    func isAvailableForRecognition() -> Bool {
        return true
    }
    
    func stopLiveRecognition() {
        stopLiveRecognitionCalled = true
        isRecognizing = false
    }
    
    func recognizeAudioFile(url: URL) async -> Result<String, SpeechRecognitionError> {
        recognizeAudioFileCalled = true
        lastAudioURL = url
        return mockRecognitionResult
    }
    
    func reset() {
        isRecognizing = false
        currentTranscript = ""
        recognitionConfidence = 0.0
        onTranscriptUpdate = nil
        onConfidenceUpdate = nil
        mockPermissionStatus = .authorized
        shouldThrowOnStart = false
        requestPermissionCalled = false
        startLiveRecognitionCalled = false
        stopLiveRecognitionCalled = false
        recognizeAudioFileCalled = false
        lastAudioURL = nil
    }
}
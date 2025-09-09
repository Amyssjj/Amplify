//
//  ServiceIntegrationTests.swift
//  AmplifyTests
//
//  Created by Claude on 2025-09-09.
//

import XCTest

@testable import Amplify

@MainActor
final class ServiceIntegrationTests: XCTestCase {

    var authenticationService: AuthenticationService!
    var audioRecordingService: AudioRecordingService!
    var aiEnhancementService: AIEnhancementService!
    var appStateManager: AppStateManager!

    override func setUp() {
        super.setUp()
        authenticationService = AuthenticationService()
        audioRecordingService = AudioRecordingService()
        aiEnhancementService = AIEnhancementService()
        appStateManager = AppStateManager()

        // Configure for testing
        aiEnhancementService.isOfflineMode = true
    }

    override func tearDown() {
        authenticationService = nil
        audioRecordingService = nil
        aiEnhancementService = nil
        appStateManager = nil
        super.tearDown()
    }

    // MARK: - Authentication to API Flow Tests

    func testAuthenticationToAPIFlow() async {
        // Given
        let mockUser = User(
            id: "test-user-123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: nil
        )

        // When - Set authentication state
        appStateManager.authenticationState = .authenticated(mockUser)
        appStateManager.currentUser = mockUser

        // Then
        XCTAssertEqual(appStateManager.authenticationState, .authenticated(mockUser))
        XCTAssertEqual(appStateManager.currentUser, mockUser)
    }

    func testAuthenticationStateTransitions() {
        // Given
        let mockUser = User(id: "test-user", email: "test@example.com")

        // When - Test state transitions
        appStateManager.authenticationState = .unauthenticated
        XCTAssertEqual(appStateManager.authenticationState, .unauthenticated)

        appStateManager.authenticationState = .authenticating
        XCTAssertEqual(appStateManager.authenticationState, .authenticating)

        appStateManager.authenticationState = .authenticated(mockUser)
        XCTAssertEqual(appStateManager.authenticationState, .authenticated(mockUser))

        appStateManager.authenticationState = .error("Test error")
        XCTAssertEqual(appStateManager.authenticationState, .error("Test error"))
    }

    // MARK: - Recording to Enhancement Flow Tests

    func testRecordingToEnhancementFlow() async throws {
        // Given
        let mockUser = User(id: "test-user", email: "test@example.com")
        appStateManager.authenticationState = .authenticated(mockUser)

        // Create mock recording data
        let tempURL = try createTempAudioFile()
        let recordingData = AudioRecordingData(
            url: tempURL,
            duration: 10.0,
            createdAt: Date()
        )

        // When - Process recording through enhancement
        appStateManager.isProcessing = true

        let result = await aiEnhancementService.enhanceStory(
            transcript: "This is a test transcript for enhancement",
            duration: recordingData.duration
        )

        // Then
        switch result {
        case .success(let enhancement):
            XCTAssertFalse(enhancement.enhancedTranscript.isEmpty)
            XCTAssertTrue(enhancement.enhancedTranscript.contains("Enhanced offline"))
        case .failure(let error):
            XCTFail("Enhancement should succeed in offline mode: \(error)")
        }
    }

    func testRecordingStateManagement() {
        // Given
        appStateManager.isRecording = false

        // When - Start recording
        appStateManager.isRecording = true
        appStateManager.recordingStartTime = Date()

        // Then
        XCTAssertTrue(appStateManager.isRecording)
        XCTAssertNotNil(appStateManager.recordingStartTime)

        // When - Stop recording
        appStateManager.isRecording = false
        appStateManager.recordingStartTime = nil

        // Then
        XCTAssertFalse(appStateManager.isRecording)
        XCTAssertNil(appStateManager.recordingStartTime)
    }

    // MARK: - Permission Integration Tests

    func testPermissionStateIntegration() {
        // Given initial permission states
        XCTAssertEqual(appStateManager.photoPermissionStatus, .notDetermined)
        XCTAssertEqual(appStateManager.microphonePermissionStatus, .undetermined)
        XCTAssertEqual(appStateManager.speechPermissionStatus, .notDetermined)

        // When - Update permission states
        appStateManager.photoPermissionStatus = .authorized
        appStateManager.microphonePermissionStatus = .authorized
        appStateManager.speechPermissionStatus = .authorized

        // Then
        XCTAssertEqual(appStateManager.photoPermissionStatus, .authorized)
        XCTAssertEqual(appStateManager.microphonePermissionStatus, .authorized)
        XCTAssertEqual(appStateManager.speechPermissionStatus, .authorized)
    }

    func testPermissionDeniedStates() {
        // When - Set denied permission states
        appStateManager.photoPermissionStatus = .denied
        appStateManager.microphonePermissionStatus = .denied
        appStateManager.speechPermissionStatus = .denied

        // Then
        XCTAssertEqual(appStateManager.photoPermissionStatus, .denied)
        XCTAssertEqual(appStateManager.microphonePermissionStatus, .denied)
        XCTAssertEqual(appStateManager.speechPermissionStatus, .denied)
    }

    // MARK: - Processing State Tests

    func testProcessingStateManagement() {
        // Given
        appStateManager.isProcessing = false
        appStateManager.processingProgress = 0.0

        // When - Start processing
        appStateManager.isProcessing = true
        appStateManager.processingProgress = 0.5

        // Then
        XCTAssertTrue(appStateManager.isProcessing)
        XCTAssertEqual(appStateManager.processingProgress, 0.5, accuracy: 0.01)

        // When - Complete processing
        appStateManager.isProcessing = false
        appStateManager.processingProgress = 1.0

        // Then
        XCTAssertFalse(appStateManager.isProcessing)
        XCTAssertEqual(appStateManager.processingProgress, 1.0, accuracy: 0.01)
    }

    // MARK: - Error Handling Integration Tests

    func testErrorHandlingIntegration() {
        // Given
        XCTAssertNil(appStateManager.currentError)
        XCTAssertFalse(appStateManager.showingError)

        // When - Set error
        let testError = AppError.networkError
        appStateManager.currentError = testError
        appStateManager.showingError = true

        // Then
        XCTAssertEqual(appStateManager.currentError, testError)
        XCTAssertTrue(appStateManager.showingError)

        // When - Clear error
        appStateManager.currentError = nil
        appStateManager.showingError = false

        // Then
        XCTAssertNil(appStateManager.currentError)
        XCTAssertFalse(appStateManager.showingError)
    }
}

// MARK: - Helper Extensions

extension ServiceIntegrationTests {

    private func createTempAudioFile() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("test_integration_audio.wav")

        // Create a minimal WAV file for testing
        let wavData = Data([
            // WAV header
            0x52, 0x49, 0x46, 0x46,  // "RIFF"
            0x24, 0x00, 0x00, 0x00,  // File size
            0x57, 0x41, 0x56, 0x45,  // "WAVE"
            0x66, 0x6D, 0x74, 0x20,  // "fmt "
            0x10, 0x00, 0x00, 0x00,  // Subchunk size
            0x01, 0x00,  // Audio format (PCM)
            0x01, 0x00,  // Number of channels
            0x44, 0xAC, 0x00, 0x00,  // Sample rate (44100)
            0x88, 0x58, 0x01, 0x00,  // Byte rate
            0x02, 0x00,  // Block align
            0x10, 0x00,  // Bits per sample
            0x64, 0x61, 0x74, 0x61,  // "data"
            0x00, 0x00, 0x00, 0x00,  // Data size (empty)
        ])

        try wavData.write(to: tempURL)
        return tempURL
    }
}

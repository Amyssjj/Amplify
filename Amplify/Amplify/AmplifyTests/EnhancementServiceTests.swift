//
//  EnhancementServiceTests.swift
//  AmplifyAPITests
//
//  Tests for the high-level EnhancementService coordination layer
//

import Foundation
import XCTest

@testable import Amplify

class EnhancementServiceTests: XCTestCase {

    var enhancementService: EnhancementService!
    var mockAPIClient: MockAPIClient!
    var mockAuthService: MockAuthenticationService!
    var mockNetworkManager: MockNetworkManager!
    var mockMapperService: ModelMapperService!

    @MainActor
    override func setUp() {
        super.setUp()

        mockAPIClient = MockAPIClient()
        mockAuthService = MockAuthenticationService()
        mockNetworkManager = MockNetworkManager()
        mockMapperService = ModelMapperService()

        enhancementService = EnhancementService(
            apiClient: mockAPIClient,
            authService: mockAuthService,
            mapperService: mockMapperService,
            networkManager: mockNetworkManager
        )
    }

    @MainActor
    override func tearDown() {
        enhancementService = nil
        mockAPIClient = nil
        mockAuthService = nil
        mockNetworkManager = nil
        mockMapperService = nil
        super.tearDown()
    }

    // MARK: - Authentication Tests

    @MainActor
    func testSignInWithGoogleSuccess() async throws {
        // Setup
        let expectedUser = User(
            id: "user_123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: nil
        )

        mockAuthService.mockUser = expectedUser
        mockAuthService.mockToken = "jwt_token_123"
        mockAuthService.mockAuthState = .authenticated(expectedUser)

        // Execute
        let result = try await enhancementService.signInWithGoogle(idToken: "google_token")

        // Verify
        XCTAssertTrue(mockAuthService.signInCalled)
        XCTAssertEqual(result.email, "test@example.com")
        XCTAssertEqual(result.name, "Test User")
        XCTAssertTrue(enhancementService.isAuthenticated)
        XCTAssertEqual(enhancementService.currentUser?.email, "test@example.com")
    }

    @MainActor
    func testSignInWithGoogleFailure() async {
        // Setup
        mockAuthService.mockAuthState = .error("Invalid token")

        // Execute & Verify
        do {
            _ = try await enhancementService.signInWithGoogle(idToken: "invalid_token")
            XCTFail("Expected sign in to fail")
        } catch {
            XCTAssertTrue(mockAuthService.signInCalled)
            XCTAssertNotNil(enhancementService.lastError)
            XCTAssertFalse(enhancementService.isAuthenticated)
        }
    }

    @MainActor
    func testSignOut() async {
        // Setup - start signed in
        let user = User(
            id: "user_123", email: "test@example.com", name: "Test", profileImageURL: nil)
        mockAuthService.mockUser = user
        mockAuthService.mockToken = "token"
        mockAuthService.mockAuthState = .authenticated(user)

        // Execute
        await enhancementService.signOut()

        // Verify
        XCTAssertTrue(mockAuthService.signOutCalled)
    }

    // MARK: - Enhancement Tests

    @MainActor
    func testEnhanceRecordingSuccess() async throws {
        // Setup authentication
        setupAuthenticatedState()

        let recording = Recording(
            id: UUID(),
            transcript: "Original story text",
            duration: 30.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let photoData = "photo_data".data(using: .utf8)!

        let apiResponse = EnhancementTextResponse(
            enhancementId: "enh_123",
            enhancedTranscript: "Enhanced story with better vocabulary and structure",
            insights: [
                "framework": "Strong narrative structure",
                "vocabulary": "Rich descriptive language",
                "engagement": "Compelling storytelling",
            ]
        )

        mockAPIClient.mockEnhancementResponse = apiResponse

        // Execute
        let result = try await enhancementService.enhanceRecording(recording, photoData: photoData)

        // Verify API call
        XCTAssertTrue(mockAPIClient.createEnhancementCalled)
        XCTAssertEqual(mockAPIClient.lastEnhancementRequest?.transcript, "Original story text")
        XCTAssertEqual(
            mockAPIClient.lastEnhancementRequest?.photoBase64, photoData.base64EncodedString())

        // Verify result mapping
        XCTAssertEqual(
            result.enhancedTranscript, "Enhanced story with better vocabulary and structure")
        XCTAssertEqual(result.insights.count, 3)

        // Verify insights mapped correctly
        let frameworkInsight = result.insights.first { $0.category == .framework }
        XCTAssertNotNil(frameworkInsight)
        XCTAssertEqual(frameworkInsight?.description, "Strong narrative structure")

        XCTAssertFalse(enhancementService.isProcessing)
        XCTAssertNil(enhancementService.lastError)
    }

    @MainActor
    func testEnhanceRecordingNotAuthenticated() async {
        // Setup - not authenticated
        mockAuthService.mockToken = nil
        mockAuthService.mockAuthState = .unauthenticated

        let recording = Recording(
            id: UUID(),
            transcript: "Test story",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let photoData = Data()

        // Execute & Verify
        do {
            _ = try await enhancementService.enhanceRecording(recording, photoData: photoData)
            XCTFail("Expected authentication error")
        } catch let error as EnhancementError {
            XCTAssertEqual(error, .notAuthenticated)
            XCTAssertFalse(mockAPIClient.createEnhancementCalled)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testEnhanceRecordingNetworkUnavailable() async {
        // Setup
        setupAuthenticatedState()
        mockNetworkManager.mockIsConnected = false

        let recording = Recording(
            id: UUID(),
            transcript: "Test story",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let photoData = Data()

        // Execute & Verify
        do {
            _ = try await enhancementService.enhanceRecording(recording, photoData: photoData)
            XCTFail("Expected network error")
        } catch let error as EnhancementError {
            XCTAssertEqual(error, .networkUnavailable)
            XCTAssertFalse(mockAPIClient.createEnhancementCalled)
        } catch {
            XCTFail("Expected EnhancementError, got: \(error)")
        }
    }

    @MainActor
    func testEnhanceRecordingAPIError() async {
        // Setup
        setupAuthenticatedState()

        mockAPIClient.shouldThrowError = true
        mockAPIClient.mockError = APIError.unauthorized("Token expired")

        let recording = Recording(
            id: UUID(),
            transcript: "Test story",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let photoData = Data()

        // Execute & Verify
        do {
            _ = try await enhancementService.enhanceRecording(recording, photoData: photoData)
            XCTFail("Expected API error")
        } catch {
            XCTAssertTrue(mockAPIClient.createEnhancementCalled)
            XCTAssertNotNil(enhancementService.lastError)
        }
    }

    // MARK: - Audio Enhancement Tests

    @MainActor
    func testGetEnhancementAudioSuccess() async throws {
        // Setup
        setupAuthenticatedState()

        let recording = Recording(
            id: UUID(),
            transcript: "Story with audio",
            duration: 45.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let audioData = "audio_content".data(using: .utf8)!
        let audioResponse = EnhancementAudioResponse(
            audioBase64: audioData,
            audioFormat: .mp3
        )

        mockAPIClient.mockAudioResponse = audioResponse

        // Execute
        let result = try await enhancementService.getEnhancementAudio(
            for: recording,
            enhancementId: "enh_audio_123"
        )

        // Verify
        XCTAssertTrue(mockAPIClient.getAudioCalled)
        XCTAssertEqual(mockAPIClient.lastEnhancementId, "enh_audio_123")
        XCTAssertEqual(result, audioData)
        XCTAssertFalse(enhancementService.isProcessing)
    }

    @MainActor
    func testGetEnhancementAudioNotAuthenticated() async {
        // Setup
        mockAuthService.mockToken = nil

        let recording = Recording(
            id: UUID(),
            transcript: "Test",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        // Execute & Verify
        do {
            _ = try await enhancementService.getEnhancementAudio(
                for: recording,
                enhancementId: "enh_123"
            )
            XCTFail("Expected authentication error")
        } catch let error as EnhancementError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Expected EnhancementError, got: \(error)")
        }
    }

    // MARK: - History Tests

    @MainActor
    func testGetEnhancementHistorySuccess() async throws {
        // Setup
        setupAuthenticatedState()

        let summary1 = EnhancementSummary(
            enhancementId: "enh_001",
            createdAt: Date(),
            transcriptPreview: "First story preview...",
            audioStatus: .ready
        )

        let summary2 = EnhancementSummary(
            enhancementId: "enh_002",
            createdAt: Date().addingTimeInterval(-3600),
            transcriptPreview: "Second story preview...",
            audioStatus: .notGenerated
        )

        let historyResponse = GetEnhancements200Response(
            total: 2,
            items: [summary1, summary2]
        )

        mockAPIClient.mockHistoryResponse = historyResponse

        // Execute
        let result = try await enhancementService.getEnhancementHistory(limit: 10, offset: 0)

        // Verify
        XCTAssertTrue(mockAPIClient.getHistoryCalled)
        XCTAssertEqual(mockAPIClient.lastHistoryParams?.limit, 10)
        XCTAssertEqual(mockAPIClient.lastHistoryParams?.offset, 0)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].transcript, "First story preview...")
        XCTAssertEqual(result[1].transcript, "Second story preview...")
    }

    @MainActor
    func testGetEnhancementHistoryDefaults() async throws {
        // Setup
        setupAuthenticatedState()

        let historyResponse = GetEnhancements200Response(total: 0, items: [])
        mockAPIClient.mockHistoryResponse = historyResponse

        // Execute - test default parameters
        let result = try await enhancementService.getEnhancementHistory()

        // Verify defaults
        XCTAssertEqual(mockAPIClient.lastHistoryParams?.limit, 20)
        XCTAssertEqual(mockAPIClient.lastHistoryParams?.offset, 0)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Enhancement Details Tests

    @MainActor
    func testGetEnhancementDetailsSuccess() async throws {
        // Setup
        setupAuthenticatedState()

        let details = EnhancementDetails(
            enhancementId: "enh_details_123",
            createdAt: Date(),
            originalTranscript: "Original story",
            enhancedTranscript: "Enhanced detailed story",
            insights: [
                "clarity": "Very clear communication",
                "structure": "Well-organized narrative",
            ],
            audioStatus: .ready,
            photoBase64: nil
        )

        mockAPIClient.mockDetailsResponse = details

        // Execute
        let result = try await enhancementService.getEnhancementDetails(
            enhancementId: "enh_details_123"
        )

        // Verify
        XCTAssertTrue(mockAPIClient.getDetailsCalled)
        XCTAssertEqual(mockAPIClient.lastEnhancementId, "enh_details_123")
        XCTAssertEqual(result.enhancementId, "enh_details_123")
        XCTAssertEqual(result.originalTranscript, "Original story")
        XCTAssertEqual(result.enhancedTranscript, "Enhanced detailed story")
        XCTAssertEqual(result.insights.count, 2)
    }

    // MARK: - Utility Tests

    @MainActor
    func testRefreshAuthenticationIfNeeded() async {
        // Setup
        mockAuthService.refreshTokenResult = true

        // Execute
        let result = await enhancementService.refreshAuthenticationIfNeeded()

        // Verify
        XCTAssertTrue(result)
        XCTAssertTrue(mockAuthService.refreshTokenCalled)
    }

    @MainActor
    func testCheckNetworkStatus() {
        // Test connected
        mockNetworkManager.mockIsConnected = true
        XCTAssertTrue(enhancementService.checkNetworkStatus())
        XCTAssertTrue(enhancementService.isNetworkAvailable)

        // Test disconnected
        mockNetworkManager.mockIsConnected = false
        XCTAssertFalse(enhancementService.checkNetworkStatus())
        XCTAssertFalse(enhancementService.isNetworkAvailable)
    }

    // MARK: - Service Factory Tests

    @MainActor
    func testProductionServiceFactory() {
        let productionService = EnhancementService.production()
        XCTAssertNotNil(productionService)
        // Production service should be configured but we can't test deep internals
    }

    @MainActor
    func testDevelopmentServiceFactory() {
        let devService = EnhancementService.development()
        XCTAssertNotNil(devService)
        // Development service should be configured but we can't test deep internals
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testEnhancementErrorDescriptions() {
        XCTAssertEqual(
            EnhancementError.notAuthenticated.localizedDescription,
            "User must be signed in to enhance recordings"
        )

        XCTAssertEqual(
            EnhancementError.networkUnavailable.localizedDescription,
            "Network connection is required"
        )

        XCTAssertEqual(
            EnhancementError.invalidResponse("test").localizedDescription,
            "Invalid API response: test"
        )

        XCTAssertEqual(
            EnhancementError.processingFailed("test").localizedDescription,
            "Enhancement processing failed: test"
        )

        XCTAssertEqual(
            EnhancementError.audioNotAvailable.localizedDescription,
            "Audio is not yet available for this enhancement"
        )
    }

    // MARK: - Helper Methods

    @MainActor
    private func setupAuthenticatedState() {
        let user = User(
            id: "user_123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: nil
        )

        mockAuthService.mockUser = user
        mockAuthService.mockToken = "valid_jwt_token"
        mockAuthService.mockAuthState = .authenticated(user)
        mockNetworkManager.mockIsConnected = true
    }
}

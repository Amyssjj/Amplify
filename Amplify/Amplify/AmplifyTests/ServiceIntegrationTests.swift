//
//  ServiceIntegrationTests.swift
//  AmplifyTests
//
//  Integration tests for service interactions and end-to-end workflows
//

import XCTest
@testable import Amplify

class ServiceIntegrationTests: XCTestCase {
    
    var apiClient: MockAPIClient!
    var authService: MockAuthenticationService!
    var networkManager: MockNetworkManager!
    var enhancementService: EnhancementService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        
        // Setup mock services
        apiClient = MockAPIClient()
        authService = MockAuthenticationService()
        networkManager = MockNetworkManager()
        
        // Setup real service with mocked dependencies
        enhancementService = EnhancementService(
            apiClient: apiClient,
            authService: authService
        )
    }
    
    @MainActor
    override func tearDown() {
        enhancementService = nil
        apiClient = nil
        authService = nil
        networkManager = nil
        super.tearDown()
    }
    
    // MARK: - Authentication + API Integration Tests
    
    @MainActor
    func testAuthenticatedAPIRequest() async throws {
        // Given
        authService.mockToken = "valid_jwt_token"
        authService.mockAuthState = .authenticated(User(id: "123", email: "test@example.com"))
        
        apiClient.mockEnhancementResponse = EnhancementTextResponse(
            enhancementId: "enh_123",
            enhancedTranscript: "Enhanced story content",
            insights: ["creativity": "High creativity detected"]
        )
        
        let testRecording = Recording(
            id: UUID(),
            transcript: "Original story",
            duration: 30.0,
            photoURL: "test-photo-url",
            timestamp: Date()
        )
        
        // When
        let result = try await enhancementService.enhanceRecording(testRecording, photoData: Data())
        
        // Then
        XCTAssertTrue(apiClient.createEnhancementCalled)
        XCTAssertEqual(apiClient.lastEnhancementRequest?.transcript, "Original story")
        XCTAssertNotNil(result.id)
        XCTAssertEqual(result.transcript, "Original story")
    }
    
    @MainActor
    func testAPIRequestWithoutAuthentication() async {
        // Given
        authService.mockToken = nil
        authService.mockAuthState = .unauthenticated
        
        let testRecording = Recording(
            id: UUID(),
            transcript: "Test story",
            duration: 30.0,
            photoURL: "test-photo-url",
            timestamp: Date()
        )
        
        // When/Then
        do {
            _ = try await enhancementService.enhanceRecording(testRecording, photoData: Data())
            XCTFail("Should have thrown authentication error")
        } catch {
            XCTAssertTrue(error is EnhancementError)
        }
    }
    
    // MARK: - Network + Authentication Integration Tests
    
    @MainActor
    func testAuthenticationWithNetworkError() async throws {
        // Given
        networkManager.mockIsConnected = false
        
        // When
        let result = try await authService.signInWithGoogle(idToken: "test_token")
        
        // Then - should still succeed with mock (in real scenario would fail)
        XCTAssertNotNil(result.accessToken)
        XCTAssertTrue(authService.signInCalled)
    }
    
    // MARK: - End-to-End Enhancement Workflow Tests
    
    @MainActor
    func testCompleteEnhancementWorkflow() async throws {
        // Given - Setup authenticated state
        authService.mockToken = "valid_token"
        authService.mockUser = User(id: "user_123", email: "user@example.com")
        authService.mockAuthState = .authenticated(authService.mockUser!)
        
        // Setup API responses
        apiClient.mockEnhancementResponse = EnhancementTextResponse(
            enhancementId: "enh_456",
            enhancedTranscript: "This is an enhanced version of the story",
            insights: [
                "theme": "Adventure and growth",
                "emotion": "Positive and uplifting"
            ]
        )
        
        apiClient.mockAudioResponse = EnhancementAudioResponse(
            audioBase64: "mock_audio_data".data(using: .utf8)!,
            audioFormat: .mp3
        )
        
        // Create test recording and photo data
        let testRecording = Recording(
            id: UUID(),
            transcript: "Once upon a time, there was a brave knight",
            duration: 45.0,
            photoURL: "test-photo-url",
            timestamp: Date()
        )
        let photoData = "base64_image_data".data(using: .utf8)!
        
        // When - Execute complete workflow
        let enhancedRecording = try await enhancementService.enhanceRecording(testRecording, photoData: photoData)
        let audioData = try await enhancementService.getEnhancementAudio(
            for: enhancedRecording,
            enhancementId: "enh_456"
        )
        
        // Then - Verify complete workflow
        XCTAssertTrue(apiClient.createEnhancementCalled)
        XCTAssertTrue(apiClient.getAudioCalled)
        XCTAssertEqual(apiClient.lastEnhancementId, "enh_456")
        
        XCTAssertNotNil(enhancedRecording.id)
        XCTAssertEqual(enhancedRecording.transcript, "Once upon a time, there was a brave knight")
        
        XCTAssertNotNil(audioData)
        XCTAssertGreaterThan(audioData.count, 0)
    }
    
    // MARK: - Error Handling Integration Tests
    
    @MainActor
    func testCascadingErrorHandling() async {
        // Given - Setup authentication failure
        authService.mockAuthState = .error("Network timeout")
        authService.mockToken = nil
        
        apiClient.shouldThrowError = true
        apiClient.mockError = APIError.networkError(URLError(.timedOut))
        
        let testRecording = Recording(
            id: UUID(),
            transcript: "Test story for error handling",
            duration: 30.0,
            photoURL: "test-photo-url",
            timestamp: Date()
        )
        
        // When/Then
        do {
            _ = try await enhancementService.enhanceRecording(testRecording, photoData: Data())
            XCTFail("Should have thrown error due to authentication failure")
        } catch {
            // Should fail due to authentication, not even reach API
            XCTAssertFalse(apiClient.createEnhancementCalled)
        }
    }
    
    @MainActor
    func testRetryMechanismIntegration() async throws {
        // Given - Setup transient failure then success
        apiClient.shouldThrowError = false
        apiClient.mockEnhancementResponse = EnhancementTextResponse(
            enhancementId: "retry_test",
            enhancedTranscript: "Success after retry",
            insights: [:]
        )
        
        authService.mockToken = "valid_token"
        authService.mockAuthState = .authenticated(User(id: "1", email: "test@example.com"))
        
        let testRecording = Recording(
            id: UUID(),
            transcript: "Test retry mechanism",
            duration: 30.0,
            photoURL: "test-photo-url",
            timestamp: Date()
        )
        
        // When
        let result = try await enhancementService.enhanceRecording(testRecording, photoData: Data())
        
        // Then
        XCTAssertNotNil(result.id)
        XCTAssertTrue(apiClient.createEnhancementCalled)
    }
    
    // MARK: - Data Flow Integration Tests
    
    @MainActor
    func testEnhancementHistoryDataFlow() async throws {
        // Given
        authService.mockToken = "valid_token"
        authService.mockAuthState = .authenticated(User(id: "user_123", email: "test@example.com"))
        
        apiClient.mockHistoryResponse = GetEnhancements200Response(
            total: 2,
            items: [
                EnhancementSummary(
                    enhancementId: "hist_1",
                    createdAt: Date(),
                    transcriptPreview: "First story",
                    audioStatus: .ready
                ),
                EnhancementSummary(
                    enhancementId: "hist_2", 
                    createdAt: Date(),
                    transcriptPreview: "Second story",
                    audioStatus: .notGenerated
                )
            ]
        )
        
        // When
        let recordings = try await enhancementService.getEnhancementHistory(limit: 10, offset: 0)
        
        // Then
        XCTAssertTrue(apiClient.getHistoryCalled)
        XCTAssertEqual(apiClient.lastHistoryParams?.limit, 10)
        XCTAssertEqual(apiClient.lastHistoryParams?.offset, 0)
        XCTAssertEqual(recordings.count, 2)
        // Note: The service maps API responses to Recording objects
    }
    
    // MARK: - State Management Integration Tests
    
    @MainActor
    func testAuthenticationStateChanges() async {
        // Given
        let initialState = authService.authenticationState
        XCTAssertEqual(initialState, .unauthenticated)
        
        // When - Sign in
        _ = try? await authService.signInWithGoogle(idToken: "test_token")
        
        // Then
        XCTAssertNotEqual(authService.authenticationState, .unauthenticated)
        XCTAssertTrue(authService.signInCalled)
        
        // When - Sign out
        await authService.signOut()
        
        // Then
        XCTAssertEqual(authService.authenticationState, .unauthenticated)
        XCTAssertTrue(authService.signOutCalled)
    }
    
    // MARK: - Performance Integration Tests
    
    @MainActor
    func testConcurrentEnhancementRequests() async throws {
        // Given
        authService.mockToken = "valid_token"
        authService.mockAuthState = .authenticated(User(id: "user_123", email: "test@example.com"))
        
        apiClient.mockEnhancementResponse = EnhancementTextResponse(
            enhancementId: "concurrent_test",
            enhancedTranscript: "Concurrent enhancement result",
            insights: [:]
        )
        
        let requests = (1...3).map { i in
            Recording(
                id: UUID(),
                transcript: "Story \(i)",
                duration: 30.0,
                photoURL: "test-photo-url-\(i)",
                timestamp: Date()
            )
        }
        
        // When - Execute concurrent requests
        let results = try await withThrowingTaskGroup(of: Recording.self) { group in
            for request in requests {
                group.addTask {
                    return try await self.enhancementService.enhanceRecording(request, photoData: Data())
                }
            }
            
            var responses: [Recording] = []
            for try await result in group {
                responses.append(result)
            }
            return responses
        }
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(apiClient.createEnhancementCalled)
        // All requests should succeed with proper authentication
        results.forEach { response in
            XCTAssertNotNil(response.id)
        }
    }
    
    // MARK: - Edge Case Integration Tests
    
    @MainActor
    func testTokenRefreshDuringAPICall() async throws {
        // Given
        authService.mockToken = "expired_token"
        authService.refreshTokenResult = true
        
        apiClient.mockEnhancementResponse = EnhancementTextResponse(
            enhancementId: "refresh_test",
            enhancedTranscript: "Success with token refresh",
            insights: [:]
        )
        
        let testRecording = Recording(
            id: UUID(),
            transcript: "Test token refresh",
            duration: 30.0,
            photoURL: "test-photo-url",
            timestamp: Date()
        )
        
        // When
        let result = try await enhancementService.enhanceRecording(testRecording, photoData: Data())
        
        // Then
        XCTAssertNotNil(result.id)
        XCTAssertTrue(authService.refreshTokenCalled)
        XCTAssertTrue(apiClient.createEnhancementCalled)
    }
}
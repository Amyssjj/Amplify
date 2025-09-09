//
//  APIClientTests.swift
//  AmplifyAPITests
//
//  Comprehensive tests for API client with JWT authentication
//

import Foundation
import XCTest

@testable import Amplify

class APIClientTests: XCTestCase {

    var apiClient: APIClient!
    var mockAuthService: MockAuthenticationService!
    var mockSession: MockURLSession!

    @MainActor
    override func setUp() {
        super.setUp()

        mockAuthService = MockAuthenticationService()
        mockSession = MockURLSession()

        apiClient = APIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            authService: mockAuthService,
            session: mockSession
        )
    }

    @MainActor
    override func tearDown() {
        apiClient = nil
        mockAuthService = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Authentication Tests

    @MainActor
    func testAuthenticationSuccess() async throws {
        // Setup
        let expectedResponse = AuthResponse(
            accessToken: "jwt_token_123",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(
                userId: "user_123",
                email: "test@example.com",
                name: "Test User",
                picture: nil
            )
        )

        mockSession.mockData = try JSONEncoder().encode(expectedResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/auth/google")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Execute
        let result = try await apiClient.authenticate(googleToken: "google_token_123")

        // Verify
        XCTAssertEqual(result.accessToken, "jwt_token_123")
        XCTAssertEqual(result.user.email, "test@example.com")

        // Verify request was made correctly
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/api/v1/auth/google")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertNil(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"))  // No auth required
    }

    @MainActor
    func testAuthenticationWithInvalidToken() async {
        // Setup
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/auth/google")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        let errorResponse = ModelErrorResponse(
            error: "INVALID_TOKEN", message: "Invalid Google ID token")
        mockSession.mockData = try! JSONEncoder().encode(errorResponse)

        // Execute & Verify
        do {
            _ = try await apiClient.authenticate(googleToken: "invalid_token")
            XCTFail("Expected authentication to fail")
        } catch let error as APIError {
            if case .unauthorized(let message) = error {
                XCTAssertEqual(message, "Invalid Google ID token")
            } else {
                XCTFail("Expected unauthorized error, got: \(error)")
            }
        } catch {
            XCTFail("Expected APIError, got: \(error)")
        }
    }

    // MARK: - Enhancement Request Tests

    @MainActor
    func testCreateEnhancementSuccess() async throws {
        // Setup
        mockAuthService.mockToken = "valid_jwt_token"

        let enhancementRequest = EnhancementRequest(
            photoBase64: "test_photo_data".data(using: .utf8)!.base64EncodedString(),
            transcript: "This is my test story",
            language: "en"
        )

        let expectedResponse = EnhancementTextResponse(
            enhancementId: "enh_123456",
            enhancedTranscript:
                "This is my enhanced test story with better vocabulary and structure.",
            insights: [
                "framework": "Clear narrative structure",
                "vocabulary": "Strong word choices",
                "pacing": "Good flow",
            ]
        )

        mockSession.mockData = try JSONEncoder().encode(expectedResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Execute
        let result = try await apiClient.createEnhancement(enhancementRequest)

        // Verify
        XCTAssertEqual(result.enhancementId, "enh_123456")
        XCTAssertTrue(result.enhancedTranscript.contains("enhanced"))
        XCTAssertEqual(result.insights["framework"], "Clear narrative structure")

        // Verify request
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/api/v1/enhancements")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(
            mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer valid_jwt_token")
        XCTAssertEqual(
            mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    @MainActor
    func testCreateEnhancementWithoutAuth() async {
        // Setup - no auth token
        mockAuthService.mockToken = nil

        let enhancementRequest = EnhancementRequest(
            photoBase64: Data().base64EncodedString(),
            transcript: "Test story",
            language: "en"
        )

        // Execute & Verify
        do {
            _ = try await apiClient.createEnhancement(enhancementRequest)
            XCTFail("Expected request to fail without authentication")
        } catch let error as APIError {
            if case .unauthorized = error {
                // Expected
            } else {
                XCTFail("Expected unauthorized error, got: \(error)")
            }
        } catch {
            XCTFail("Expected APIError, got: \(error)")
        }
    }

    @MainActor
    func testCreateEnhancementValidationError() async throws {
        // Setup
        mockAuthService.mockToken = "valid_token"

        let validationError = ValidationErrorResponse(
            error: .validationError,
            message: "Request validation failed",
            validationErrors: [
                ValidationErrorResponseValidationErrorsInner(
                    field: "transcript",
                    message: "Transcript cannot be empty"
                )
            ]
        )

        mockSession.mockData = try JSONEncoder().encode(validationError)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )

        let enhancementRequest = EnhancementRequest(
            photoBase64: Data().base64EncodedString(),
            transcript: "",  // Empty transcript
            language: "en"
        )

        // Execute & Verify
        do {
            _ = try await apiClient.createEnhancement(enhancementRequest)
            XCTFail("Expected validation error")
        } catch let error as APIError {
            if case .validationError(let validationResponse) = error {
                XCTAssertEqual(validationResponse.validationErrors.first?.field, "transcript")
            } else {
                XCTFail("Expected validation error, got: \(error)")
            }
        }
    }

    // MARK: - Audio Response Tests

    @MainActor
    func testGetEnhancementAudioSuccess() async throws {
        // Setup
        mockAuthService.mockToken = "valid_token"

        let audioResponse = EnhancementAudioResponse(
            audioBase64: "fake_mp3_audio_data".data(using: .utf8)!,
            audioFormat: .mp3
        )

        mockSession.mockData = try JSONEncoder().encode(audioResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements/enh_123/audio")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Execute
        let result = try await apiClient.getEnhancementAudio(id: "enh_123")

        // Verify
        XCTAssertEqual(result.audioFormat, .mp3)
        XCTAssertGreaterThan(result.audioBase64.count, 0)

        // Verify request
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/api/v1/enhancements/enh_123/audio")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "GET")
    }

    @MainActor
    func testGetEnhancementAudioNotFound() async {
        // Setup
        mockAuthService.mockToken = "valid_token"

        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements/invalid_id/audio")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )

        let errorResponse = ModelErrorResponse(error: "NOT_FOUND", message: "Enhancement not found")
        mockSession.mockData = try! JSONEncoder().encode(errorResponse)

        // Execute & Verify
        do {
            _ = try await apiClient.getEnhancementAudio(id: "invalid_id")
            XCTFail("Expected not found error")
        } catch let error as APIError {
            if case .notFound = error {
                // Expected
            } else {
                XCTFail("Expected not found error, got: \(error)")
            }
        } catch {
            XCTFail("Expected APIError, got: \(error)")
        }
    }

    // MARK: - History Tests

    @MainActor
    func testGetEnhancementHistorySuccess() async throws {
        // Setup
        mockAuthService.mockToken = "valid_token"

        let historyResponse = GetEnhancements200Response(
            total: 2,
            items: [
                EnhancementSummary(
                    enhancementId: "enh_123",
                    createdAt: Date(),
                    transcriptPreview: "This is a preview...",
                    audioStatus: .ready
                ),
                EnhancementSummary(
                    enhancementId: "enh_456",
                    createdAt: Date(),
                    transcriptPreview: "Another preview...",
                    audioStatus: .notGenerated
                ),
            ]
        )

        mockSession.mockData = try JSONEncoder().encode(historyResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Execute
        let result = try await apiClient.getEnhancementHistory(limit: 10, offset: 0)

        // Verify
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.first?.enhancementId, "enh_123")

        // Verify query parameters
        XCTAssertTrue(mockSession.lastRequest?.url?.query?.contains("limit=10") == true)
        XCTAssertTrue(mockSession.lastRequest?.url?.query?.contains("offset=0") == true)
    }

    // MARK: - Token Refresh Tests

    @MainActor
    func testTokenRefreshOnUnauthorized() async throws {
        // Setup
        mockAuthService.mockToken = "expired_token"

        // First request fails with 401
        let unauthorizedResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        // Mock auth service to refresh token
        mockAuthService.refreshTokenResult = true
        mockAuthService.mockToken = "refreshed_token"

        // Second request succeeds
        let successResponse = EnhancementTextResponse(
            enhancementId: "enh_789",
            enhancedTranscript: "Success after refresh",
            insights: [:]
        )

        // Setup mock to return different responses for different requests
        mockSession.responseQueue = [
            (
                try! JSONEncoder().encode(
                    ModelErrorResponse(error: "UNAUTHORIZED", message: "Token expired")),
                unauthorizedResponse!
            ),
            (
                try! JSONEncoder().encode(successResponse),
                HTTPURLResponse(
                    url: URL(string: "http://localhost:8000/api/v1/enhancements")!, statusCode: 200,
                    httpVersion: nil, headerFields: nil)!
            ),
        ]

        let request = EnhancementRequest(
            photoBase64: Data().base64EncodedString(),
            transcript: "Test story",
            language: "en"
        )

        // Execute
        let result = try await apiClient.createEnhancement(request)

        // Verify
        XCTAssertEqual(result.enhancementId, "enh_789")
        XCTAssertTrue(mockAuthService.refreshTokenCalled)
    }

    // MARK: - Rate Limiting Tests

    @MainActor
    func testRateLimitingWithRetry() async throws {
        // Setup
        mockAuthService.mockToken = "valid_token"

        let rateLimitResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )

        let successResponse = EnhancementTextResponse(
            enhancementId: "enh_success",
            enhancedTranscript: "Success after retry",
            insights: [:]
        )

        // Setup responses: first fails with 429, second succeeds
        mockSession.responseQueue = [
            (
                try! JSONEncoder().encode(
                    ModelErrorResponse(error: "RATE_LIMITED", message: "Too many requests")),
                rateLimitResponse!
            ),
            (
                try! JSONEncoder().encode(successResponse),
                HTTPURLResponse(
                    url: URL(string: "http://localhost:8000/api/v1/enhancements")!, statusCode: 200,
                    httpVersion: nil, headerFields: nil)!
            ),
        ]

        let request = EnhancementRequest(
            photoBase64: Data().base64EncodedString(),
            transcript: "Test story",
            language: "en"
        )

        // Execute
        let result = try await apiClient.createEnhancement(request)

        // Verify
        XCTAssertEqual(result.enhancementId, "enh_success")
        XCTAssertEqual(mockSession.requestCount, 2)  // Should have retried
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testNetworkErrorHandling() async {
        // Setup
        mockAuthService.mockToken = "valid_token"
        mockSession.shouldThrowError = true
        mockSession.mockError = URLError(.notConnectedToInternet)

        let request = EnhancementRequest(
            photoBase64: Data().base64EncodedString(),
            transcript: "Test story",
            language: "en"
        )

        // Execute & Verify
        do {
            _ = try await apiClient.createEnhancement(request)
            XCTFail("Expected network error")
        } catch let error as APIError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected network error, got: \(error)")
            }
        } catch {
            XCTFail("Expected APIError, got: \(error)")
        }
    }

    @MainActor
    func testJSONDecodingError() async {
        // Setup
        mockAuthService.mockToken = "valid_token"

        mockSession.mockData = "invalid json".data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/v1/enhancements")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let request = EnhancementRequest(
            photoBase64: Data().base64EncodedString(),
            transcript: "Test story",
            language: "en"
        )

        // Execute & Verify
        do {
            _ = try await apiClient.createEnhancement(request)
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected decoding error, got: \(error)")
            }
        } catch {
            XCTFail("Expected APIError, got: \(error)")
        }
    }
}

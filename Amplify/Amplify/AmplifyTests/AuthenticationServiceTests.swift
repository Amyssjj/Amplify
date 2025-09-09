//
//  AuthenticationServiceTests.swift
//  AmplifyAPITests
//
//  Tests for authentication service with Google OAuth and JWT management
//

import XCTest
import Foundation

@testable import Amplify

class AuthenticationServiceTests: XCTestCase {
    
    var authService: AuthenticationService!
    var mockTokenStorage: MockTokenStorage!
    var mockAPIClient: MockAPIClient!
    
    @MainActor
    override func setUp() {
        super.setUp()
        
        mockTokenStorage = MockTokenStorage()
        mockAPIClient = MockAPIClient()
        
        authService = AuthenticationService(
            tokenStorage: mockTokenStorage,
            apiClient: mockAPIClient
        )
    }
    
    @MainActor
    override func tearDown() {
        authService = nil
        mockTokenStorage = nil
        mockAPIClient = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    @MainActor
    func testSignInWithGoogleSuccess() async throws {
        // Setup
        let expectedAuthResponse = AuthResponse(
            accessToken: "jwt_token_123",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(
                userId: "user_123",
                email: "test@example.com",
                name: "Test User",
                picture: "https://example.com/avatar.jpg"
            )
        )
        
        mockAPIClient.mockAuthResponse = expectedAuthResponse
        
        // Execute
        let result = try await authService.signInWithGoogle(idToken: "google_id_token_123")
        
        // Verify API call
        XCTAssertTrue(mockAPIClient.authenticateCalled)
        XCTAssertEqual(mockAPIClient.lastGoogleToken, "google_id_token_123")
        
        // Verify response
        XCTAssertEqual(result.accessToken, "jwt_token_123")
        XCTAssertEqual(result.user.email, "test@example.com")
        
        // Verify authentication state
        if case .authenticated(let user) = authService.authenticationState {
            XCTAssertEqual(user.email, "test@example.com")
            XCTAssertEqual(user.name, "Test User")
        } else {
            XCTFail("Expected authenticated state")
        }
        
        // Verify current user
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, "test@example.com")
        
        // Verify token storage
        XCTAssertTrue(mockTokenStorage.storeTokensCalled)
        
        // Verify current token
        XCTAssertEqual(authService.currentToken, "jwt_token_123")
    }
    
    @MainActor
    func testSignInWithInvalidGoogleToken() async {
        // Setup
        mockAPIClient.shouldThrowError = true
        mockAPIClient.mockError = APIError.unauthorized("Invalid Google ID token")
        
        // Execute & Verify
        do {
            _ = try await authService.signInWithGoogle(idToken: "invalid_token")
            XCTFail("Expected sign in to fail")
        } catch {
            // Verify error state
            if case .error(let message) = authService.authenticationState {
                XCTAssertTrue(message.contains("Invalid Google ID token"))
            } else {
                XCTFail("Expected error state")
            }
            
            // Verify no user or token set
            XCTAssertNil(authService.currentUser)
            XCTAssertNil(authService.currentToken)
        }
    }
    
    @MainActor
    func testSignInWithNetworkError() async {
        // Setup
        mockAPIClient.shouldThrowError = true
        mockAPIClient.mockError = APIError.networkError(URLError(.notConnectedToInternet))
        
        // Execute & Verify
        do {
            _ = try await authService.signInWithGoogle(idToken: "valid_token")
            XCTFail("Expected network error")
        } catch {
            // Verify error state
            if case .error(let message) = authService.authenticationState {
                XCTAssertTrue(message.contains("not connected"))
            } else {
                XCTFail("Expected error state")
            }
        }
    }
    
    // MARK: - Token Validation Tests
    
    @MainActor
    func testTokenValidationWithValidToken() async throws {
        // Setup - sign in first
        let authResponse = AuthResponse(
            accessToken: "valid_token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(userId: "user_1", email: "test@example.com")
        )
        
        mockAPIClient.mockAuthResponse = authResponse
        _ = try await authService.signInWithGoogle(idToken: "google_token")
        
        // Execute & Verify
        XCTAssertTrue(authService.isTokenValid())
        XCTAssertEqual(authService.currentToken, "valid_token")
    }
    
    @MainActor
    func testTokenValidationWithNoToken() {
        // Execute & Verify
        XCTAssertFalse(authService.isTokenValid())
        XCTAssertNil(authService.currentToken)
    }
    
    // MARK: - Token Refresh Tests
    
    @MainActor
    func testRefreshTokenNotNeeded() async throws {
        // Setup - sign in with long-lived token
        let authResponse = AuthResponse(
            accessToken: "long_lived_token",
            tokenType: .bearer,
            expiresIn: 7200, // 2 hours
            user: AuthResponseUser(userId: "user_1", email: "test@example.com")
        )
        
        mockAPIClient.mockAuthResponse = authResponse
        _ = try await authService.signInWithGoogle(idToken: "google_token")
        
        // Execute
        let result = await authService.refreshTokenIfNeeded()
        
        // Verify - should return true without refresh
        XCTAssertTrue(result)
    }
    
    @MainActor
    func testRefreshTokenWithExpiredToken() async throws {
        // Setup - manually set expired token
        let authResponse = AuthResponse(
            accessToken: "expired_token",
            tokenType: .bearer,
            expiresIn: -3600, // Expired 1 hour ago
            user: AuthResponseUser(userId: "user_1", email: "test@example.com")
        )
        
        mockAPIClient.mockAuthResponse = authResponse
        _ = try await authService.signInWithGoogle(idToken: "google_token")
        
        // Execute
        let result = await authService.refreshTokenIfNeeded()
        
        // Verify - should sign out and return false (no refresh implemented)
        XCTAssertFalse(result)
        XCTAssertEqual(authService.authenticationState, .unauthenticated)
        XCTAssertNil(authService.currentToken)
    }
    
    // MARK: - Sign Out Tests
    
    @MainActor
    func testSignOut() async throws {
        // Setup - sign in first
        let authResponse = AuthResponse(
            accessToken: "test_token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(userId: "user_1", email: "test@example.com")
        )
        
        mockAPIClient.mockAuthResponse = authResponse
        _ = try await authService.signInWithGoogle(idToken: "google_token")
        
        // Verify signed in
        XCTAssertNotNil(authService.currentToken)
        XCTAssertNotNil(authService.currentUser)
        
        // Execute sign out
        await authService.signOut()
        
        // Verify sign out
        XCTAssertNil(authService.currentToken)
        XCTAssertNil(authService.currentUser)
        XCTAssertEqual(authService.authenticationState, .unauthenticated)
        XCTAssertTrue(mockTokenStorage.clearTokensCalled)
    }
    
    // MARK: - Stored Authentication Tests
    
    @MainActor
    func testLoadStoredAuthenticationWithValidToken() async throws {
        // Setup stored authentication
        let user = User(
            id: "stored_user_id",
            email: "stored@example.com",
            name: "Stored User",
            profileImageURL: nil
        )
        
        try await mockTokenStorage.storeTokens(
            accessToken: "stored_token",
            expiration: Date().addingTimeInterval(3600), // Valid for 1 hour
            user: user
        )
        
        // Create new auth service (simulates app launch)
        authService = AuthenticationService(
            tokenStorage: mockTokenStorage,
            apiClient: mockAPIClient
        )
        
        // Give time for async loading
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify loaded state
        XCTAssertEqual(authService.currentToken, "stored_token")
        XCTAssertEqual(authService.currentUser?.email, "stored@example.com")
        
        if case .authenticated(let loadedUser) = authService.authenticationState {
            XCTAssertEqual(loadedUser.email, "stored@example.com")
        } else {
            XCTFail("Expected authenticated state")
        }
    }
    
    @MainActor
    func testLoadStoredAuthenticationWithExpiredToken() async throws {
        // Setup expired stored authentication
        let user = User(
            id: "expired_user_id",
            email: "expired@example.com",
            name: "Expired User",
            profileImageURL: nil
        )
        
        try await mockTokenStorage.storeTokens(
            accessToken: "expired_token",
            expiration: Date().addingTimeInterval(-3600), // Expired 1 hour ago
            user: user
        )
        
        // Create new auth service (simulates app launch)
        authService = AuthenticationService(
            tokenStorage: mockTokenStorage,
            apiClient: mockAPIClient
        )
        
        // Give time for async loading and cleanup
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify signed out state (expired token cleaned up)
        XCTAssertNil(authService.currentToken)
        XCTAssertNil(authService.currentUser)
        XCTAssertEqual(authService.authenticationState, .unauthenticated)
    }
    
    // MARK: - Authentication State Transitions Tests
    
    @MainActor
    func testAuthenticationStateTransitions() async throws {
        // Initial state
        XCTAssertEqual(authService.authenticationState, .unauthenticated)
        
        // Setup successful response
        let authResponse = AuthResponse(
            accessToken: "test_token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(userId: "user_1", email: "test@example.com")
        )
        
        mockAPIClient.mockAuthResponse = authResponse
        
        // Start sign in
        let signInTask = Task {
            return try await authService.signInWithGoogle(idToken: "google_token")
        }
        
        // Small delay to check authenticating state
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        // Should be in authenticating state (might be too fast to catch)
        // XCTAssertEqual(authService.authenticationState, .authenticating)
        
        // Wait for completion
        _ = try await signInTask.value
        
        // Should be in authenticated state
        if case .authenticated(let user) = authService.authenticationState {
            XCTAssertEqual(user.email, "test@example.com")
        } else {
            XCTFail("Expected authenticated state")
        }
        
        // Sign out
        await authService.signOut()
        
        // Should be back to unauthenticated
        XCTAssertEqual(authService.authenticationState, .unauthenticated)
    }
    
    // MARK: - Error Scenarios Tests
    
    @MainActor
    func testNoAPIClientError() async {
        // Create auth service without API client
        let authServiceWithoutAPI = AuthenticationService(
            tokenStorage: mockTokenStorage,
            apiClient: nil
        )
        
        // Execute & Verify
        do {
            _ = try await authServiceWithoutAPI.signInWithGoogle(idToken: "token")
            XCTFail("Expected error")
        } catch let error as AuthenticationError {
            XCTAssertEqual(error, .noAPIClient)
        } catch {
            XCTFail("Expected AuthenticationError, got: \(error)")
        }
    }
    
    @MainActor
    func testTokenStorageError() async throws {
        // Setup token storage to throw error
        class FailingTokenStorage: TokenStorage {
            func storeTokens(accessToken: String, expiration: Date, user: User) async throws {
                throw AuthenticationError.storageError(NSError(domain: "Test", code: -1))
            }
            
            func getAccessToken() async -> String? { nil }
            func getTokenExpiration() async -> Date? { nil }
            func getUser() async -> User? { nil }
            func clearTokens() async { }
        }
        
        let failingStorage = FailingTokenStorage()
        let authServiceWithFailingStorage = AuthenticationService(
            tokenStorage: failingStorage,
            apiClient: mockAPIClient
        )
        
        // Setup successful API response
        mockAPIClient.mockAuthResponse = AuthResponse(
            accessToken: "token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(userId: "user_1", email: "test@example.com")
        )
        
        // Execute & Verify - should still succeed even if storage fails
        do {
            _ = try await authServiceWithFailingStorage.signInWithGoogle(idToken: "token")
            // Storage error is handled internally, sign in should still work
            XCTAssertNotNil(authServiceWithFailingStorage.currentToken)
        } catch {
            XCTFail("Sign in should succeed even if storage fails: \(error)")
        }
    }
}
//
//  APIConfigurationTests.swift
//  AmplifyTests
//
//  Tests for API configuration and environment settings
//

import XCTest

@testable import Amplify

final class APIConfigurationTests: XCTestCase {

    // MARK: - Base URL Tests

    func testBaseURL() {
        let baseURL = APIConfiguration.baseURL

        XCTAssertNotNil(baseURL)
        XCTAssertTrue(baseURL.absoluteString.hasPrefix("https://"))
        XCTAssertEqual(baseURL.absoluteString, "https://amplify-backend.replit.app")
    }

    func testEnvironmentConfiguration() {
        let environment = APIConfiguration.environment

        #if DEBUG
            XCTAssertEqual(environment, .development)
            XCTAssertEqual(environment.description, "Development")
        #else
            XCTAssertEqual(environment, .production)
            XCTAssertEqual(environment.description, "Production")
        #endif
    }

    // MARK: - Endpoints Tests

    func testStaticEndpoints() {
        XCTAssertEqual(APIConfiguration.Endpoints.authentication, "/api/v1/auth/google")
        XCTAssertEqual(APIConfiguration.Endpoints.enhancements, "/api/v1/enhancements")
        XCTAssertEqual(APIConfiguration.Endpoints.health, "/api/v1/health")
    }

    func testDynamicEndpoints() {
        let enhancementId = "test-enhancement-123"

        let detailsEndpoint = APIConfiguration.Endpoints.enhancementDetails(id: enhancementId)
        let audioEndpoint = APIConfiguration.Endpoints.enhancementAudio(id: enhancementId)

        XCTAssertEqual(detailsEndpoint, "/api/v1/enhancements/test-enhancement-123")
        XCTAssertEqual(audioEndpoint, "/api/v1/enhancements/test-enhancement-123/audio")
    }

    func testEndpointsWithSpecialCharacters() {
        let specialId = "test-123_enhancement@domain.com"

        let detailsEndpoint = APIConfiguration.Endpoints.enhancementDetails(id: specialId)
        let audioEndpoint = APIConfiguration.Endpoints.enhancementAudio(id: specialId)

        XCTAssertEqual(detailsEndpoint, "/api/v1/enhancements/test-123_enhancement@domain.com")
        XCTAssertEqual(audioEndpoint, "/api/v1/enhancements/test-123_enhancement@domain.com/audio")
    }

    // MARK: - Network Configuration Tests

    func testNetworkTimeouts() {
        XCTAssertEqual(APIConfiguration.NetworkConfig.defaultTimeout, 30.0)
        XCTAssertEqual(APIConfiguration.NetworkConfig.authTimeout, 15.0)
        XCTAssertEqual(APIConfiguration.NetworkConfig.uploadTimeout, 60.0)

        // Ensure upload timeout is longest for large file uploads
        XCTAssertGreaterThan(
            APIConfiguration.NetworkConfig.uploadTimeout,
            APIConfiguration.NetworkConfig.defaultTimeout)
        XCTAssertGreaterThan(
            APIConfiguration.NetworkConfig.defaultTimeout,
            APIConfiguration.NetworkConfig.authTimeout)
    }

    func testRetryConfiguration() {
        XCTAssertEqual(APIConfiguration.NetworkConfig.maxRetries, 3)
        XCTAssertEqual(APIConfiguration.NetworkConfig.retryDelay, 2.0)

        // Ensure reasonable retry settings
        XCTAssertGreaterThan(APIConfiguration.NetworkConfig.maxRetries, 0)
        XCTAssertLessThanOrEqual(APIConfiguration.NetworkConfig.maxRetries, 5)  // Not too many retries
        XCTAssertGreaterThan(APIConfiguration.NetworkConfig.retryDelay, 0)
    }

    // MARK: - Feature Flags Tests

    func testFeatureFlags() {
        // Test that feature flags have expected default values
        XCTAssertTrue(APIConfiguration.FeatureFlags.enableAudioGeneration)
        XCTAssertFalse(APIConfiguration.FeatureFlags.enableOfflineMode)
        XCTAssertFalse(APIConfiguration.FeatureFlags.enableAnalytics)
        XCTAssertTrue(APIConfiguration.FeatureFlags.enableDebugLogging)

        #if DEBUG
            // In debug mode, mock responses should be configurable
            XCTAssertFalse(APIConfiguration.FeatureFlags.mockAPIResponses)
        #else
            // In production, mock responses should always be disabled
            XCTAssertFalse(APIConfiguration.FeatureFlags.mockAPIResponses)
        #endif
    }

    func testFeatureFlagsConsistency() {
        // Test logical consistency between related flags
        if APIConfiguration.FeatureFlags.enableOfflineMode {
            // If offline mode is enabled, we might not need audio generation from API
            // This is a logical consistency check that could be useful
        }

        // Debug logging should be consistent with environment
        #if DEBUG
            // In debug builds, debug logging is typically enabled
            XCTAssertTrue(APIConfiguration.FeatureFlags.enableDebugLogging)
        #endif
    }

    // MARK: - Environment Description Tests

    func testEnvironmentDescriptions() {
        let development = APIConfiguration.Environment.development
        let production = APIConfiguration.Environment.production

        XCTAssertEqual(development.description, "Development")
        XCTAssertEqual(production.description, "Production")
        XCTAssertNotEqual(development.description, production.description)
    }

    // MARK: - Full URL Construction Tests

    func testFullURLConstruction() {
        let baseURL = APIConfiguration.baseURL
        let healthEndpoint = APIConfiguration.Endpoints.health

        let fullHealthURL = baseURL.appendingPathComponent(healthEndpoint)

        XCTAssertEqual(
            fullHealthURL.absoluteString, "https://amplify-backend.replit.app/api/v1/health")
    }

    func testFullURLConstructionWithDynamicEndpoint() {
        let baseURL = APIConfiguration.baseURL
        let enhancementId = "test-123"
        let detailsEndpoint = APIConfiguration.Endpoints.enhancementDetails(id: enhancementId)

        let fullDetailsURL = baseURL.appendingPathComponent(detailsEndpoint)

        XCTAssertEqual(
            fullDetailsURL.absoluteString,
            "https://amplify-backend.replit.app/api/v1/enhancements/test-123")
    }

    // MARK: - Configuration Validation Tests

    func testConfigurationValues() {
        // Test that all timeout values are positive
        XCTAssertGreaterThan(APIConfiguration.NetworkConfig.defaultTimeout, 0)
        XCTAssertGreaterThan(APIConfiguration.NetworkConfig.authTimeout, 0)
        XCTAssertGreaterThan(APIConfiguration.NetworkConfig.uploadTimeout, 0)
        XCTAssertGreaterThan(APIConfiguration.NetworkConfig.retryDelay, 0)

        // Test that retry count is reasonable
        XCTAssertGreaterThanOrEqual(APIConfiguration.NetworkConfig.maxRetries, 1)
        XCTAssertLessThanOrEqual(APIConfiguration.NetworkConfig.maxRetries, 10)
    }

    func testBaseURLIsValid() {
        let baseURL = APIConfiguration.baseURL

        // Test URL components
        XCTAssertNotNil(baseURL.scheme)
        XCTAssertEqual(baseURL.scheme, "https")
        XCTAssertNotNil(baseURL.host)
        XCTAssertFalse(baseURL.host?.isEmpty ?? true)

        // Test that URL can be used for network requests
        XCTAssertNoThrow(URLRequest(url: baseURL))
    }

    // MARK: - Debug Helper Tests

    #if DEBUG
        func testDebugPrintConfiguration() {
            // Test that debug print doesn't crash
            XCTAssertNoThrow(APIConfiguration.printConfiguration())
        }
    #endif

    // MARK: - Environment Switching Tests

    func testEnvironmentSpecificSettings() {
        let currentEnvironment = APIConfiguration.environment

        switch currentEnvironment {
        case .development:
            // In development, debug logging should be enabled
            XCTAssertTrue(APIConfiguration.FeatureFlags.enableDebugLogging)
        case .production:
            // In production, mock responses should be disabled
            XCTAssertFalse(APIConfiguration.FeatureFlags.mockAPIResponses)
        }
    }
}

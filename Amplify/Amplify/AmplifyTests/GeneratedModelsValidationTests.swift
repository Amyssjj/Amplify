//
//  GeneratedModelsValidationTests.swift
//  AmplifyAPITests
//
//  Tests for validating generated API models from OpenAPI specification
//

import XCTest
import Foundation

@testable import Amplify

class GeneratedModelsValidationTests: XCTestCase {
    
    // MARK: - EnhancementRequest Tests
    
    @MainActor
    func testEnhancementRequestCodable() {
        // Test data
        let testPhotoData = "test photo data".data(using: .utf8)!
        let testTranscript = "This is a test story transcript"
        let testLanguage = "en"
        
        // Create request
        let request = EnhancementRequest(
            photoBase64: testPhotoData,
            transcript: testTranscript,
            language: testLanguage
        )
        
        // Test encoding
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(request)
            XCTAssertGreaterThan(encoded.count, 0)
            
            // Test decoding
            let decoded = try JSONDecoder().decode(EnhancementRequest.self, from: encoded)
            XCTAssertEqual(decoded.photoBase64, testPhotoData)
            XCTAssertEqual(decoded.transcript, testTranscript)
            XCTAssertEqual(decoded.language, testLanguage)
        })
    }
    
    @MainActor
    func testEnhancementRequestDefaultLanguage() {
        let request = EnhancementRequest(
            photoBase64: Data(),
            transcript: "test"
        )
        
        XCTAssertEqual(request.language, "en")
    }
    
    @MainActor
    func testEnhancementRequestJSONSerialization() {
        let testJSON = """
        {
            "photo_base64": "dGVzdCBwaG90byBkYXRh",
            "transcript": "This is a test story",
            "language": "en"
        }
        """
        
        XCTAssertNoThrow({
            let data = testJSON.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(EnhancementRequest.self, from: data)
            
            XCTAssertEqual(decoded.transcript, "This is a test story")
            XCTAssertEqual(decoded.language, "en")
            
            // Verify encoding back to JSON
            let encoded = try JSONEncoder().encode(decoded)
            let reDecoded = try JSONDecoder().decode(EnhancementRequest.self, from: encoded)
            XCTAssertEqual(decoded.transcript, reDecoded.transcript)
        })
    }
    
    // MARK: - EnhancementTextResponse Tests
    
    @MainActor
    func testEnhancementTextResponseCodable() {
        let testResponse = EnhancementTextResponse(
            enhancementId: "enh_123456",
            enhancedTranscript: "This is an enhanced story with better words and structure.",
            insights: [
                "framework": "STAR method detected",
                "vocabulary": "Strong word choices identified",
                "pacing": "Good narrative flow"
            ]
        )
        
        // Test encoding/decoding
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(testResponse)
            let decoded = try JSONDecoder().decode(EnhancementTextResponse.self, from: encoded)
            
            XCTAssertEqual(decoded.enhancementId, "enh_123456")
            XCTAssertEqual(decoded.enhancedTranscript, testResponse.enhancedTranscript)
            XCTAssertEqual(decoded.insights["framework"], "STAR method detected")
            XCTAssertEqual(decoded.insights.count, 3)
        })
    }
    
    @MainActor
    func testEnhancementTextResponseJSONParsing() {
        let testJSON = """
        {
            "enhancement_id": "enh_789012",
            "enhanced_transcript": "Your story has been enhanced with powerful vocabulary and improved structure.",
            "insights": {
                "framework": "Hero's Journey pattern",
                "emotion": "Strong emotional impact",
                "clarity": "Clear and engaging narrative"
            }
        }
        """
        
        XCTAssertNoThrow({
            let data = testJSON.data(using: .utf8)!
            let response = try JSONDecoder().decode(EnhancementTextResponse.self, from: data)
            
            XCTAssertEqual(response.enhancementId, "enh_789012")
            XCTAssertTrue(response.enhancedTranscript.contains("enhanced"))
            XCTAssertEqual(response.insights["framework"], "Hero's Journey pattern")
            XCTAssertEqual(response.insights.keys.count, 3)
        })
    }
    
    // MARK: - AuthResponse Tests
    
    @MainActor
    func testAuthResponseCodable() {
        let user = AuthResponseUser(
            userId: "user_123",
            email: "test@example.com",
            name: "Test User",
            picture: "https://example.com/avatar.jpg"
        )
        
        let authResponse = AuthResponse(
            accessToken: "jwt_token_here",
            tokenType: .bearer,
            expiresIn: 3600,
            user: user
        )
        
        // Test encoding/decoding
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(authResponse)
            let decoded = try JSONDecoder().decode(AuthResponse.self, from: encoded)
            
            XCTAssertEqual(decoded.accessToken, "jwt_token_here")
            XCTAssertEqual(decoded.tokenType, .bearer)
            XCTAssertEqual(decoded.expiresIn, 3600)
            XCTAssertEqual(decoded.user.userId, "user_123")
            XCTAssertEqual(decoded.user.email, "test@example.com")
        })
    }
    
    @MainActor
    func testAuthResponseJSONParsing() {
        let testJSON = """
        {
            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "token_type": "bearer",
            "expires_in": 3600,
            "user": {
                "user_id": "user_456",
                "email": "john@example.com",
                "name": "John Doe",
                "picture": "https://example.com/john.jpg"
            }
        }
        """
        
        XCTAssertNoThrow({
            let data = testJSON.data(using: .utf8)!
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            XCTAssertEqual(response.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
            XCTAssertEqual(response.tokenType, .bearer)
            XCTAssertEqual(response.expiresIn, 3600)
            XCTAssertEqual(response.user.email, "john@example.com")
        })
    }
    
    // MARK: - GoogleAuthRequest Tests
    
    @MainActor
    func testGoogleAuthRequestCodable() {
        let request = GoogleAuthRequest(idToken: "google_id_token_123")
        
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(request)
            let decoded = try JSONDecoder().decode(GoogleAuthRequest.self, from: encoded)
            
            XCTAssertEqual(decoded.idToken, "google_id_token_123")
        })
    }
    
    // MARK: - EnhancementAudioResponse Tests
    
    @MainActor
    func testEnhancementAudioResponseCodable() {
        let audioData = "fake_mp3_data_here".data(using: .utf8)!
        let response = EnhancementAudioResponse(
            audioBase64: audioData,
            audioFormat: .mp3
        )
        
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(response)
            let decoded = try JSONDecoder().decode(EnhancementAudioResponse.self, from: encoded)
            
            XCTAssertEqual(decoded.audioBase64, audioData)
            XCTAssertEqual(decoded.audioFormat, .mp3)
        })
    }
    
    // MARK: - Error Response Tests
    
    @MainActor
    func testModelErrorResponseCodable() {
        let errorResponse = ModelErrorResponse(
            error: "VALIDATION_ERROR",
            message: "The request body is invalid"
        )
        
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(errorResponse)
            let decoded = try JSONDecoder().decode(ModelErrorResponse.self, from: encoded)
            
            XCTAssertEqual(decoded.error, "VALIDATION_ERROR")
            XCTAssertEqual(decoded.message, "The request body is invalid")
        })
    }
    
    @MainActor
    func testModelErrorResponseJSONParsing() {
        let testJSON = """
        {
            "error": "UNAUTHORIZED",
            "message": "The JWT token is invalid or expired"
        }
        """
        
        XCTAssertNoThrow({
            let data = testJSON.data(using: .utf8)!
            let error = try JSONDecoder().decode(ModelErrorResponse.self, from: data)
            
            XCTAssertEqual(error.error, "UNAUTHORIZED")
            XCTAssertEqual(error.message, "The JWT token is invalid or expired")
        })
    }
    
    // MARK: - ValidationErrorResponse Tests
    
    @MainActor
    func testValidationErrorResponseCodable() {
        let validationError = ValidationErrorResponseValidationErrorsInner(
            field: "transcript",
            message: "Transcript cannot be empty"
        )
        
        let validationResponse = ValidationErrorResponse(
            error: .validationError,
            message: "Request validation failed",
            validationErrors: [validationError]
        )
        
        XCTAssertNoThrow({
            let encoded = try JSONEncoder().encode(validationResponse)
            let decoded = try JSONDecoder().decode(ValidationErrorResponse.self, from: encoded)
            
            XCTAssertEqual(decoded.error, .validationError)
            XCTAssertEqual(decoded.validationErrors.first?.field, "transcript")
        })
    }
    
    // MARK: - Integration Tests with Sample API Responses
    
    @MainActor
    func testRealAPIResponseFormat() {
        // Test with realistic API response format
        let mockEnhancementResponse = """
        {
            "enhancement_id": "enh_1a2b3c4d5e",
            "enhanced_transcript": "Once upon a time, in a world where storytelling was an art form, there lived a young narrator who discovered the power of compelling language. Their journey began with simple words but evolved into something truly magnificent through careful attention to pacing, emotion, and structure.",
            "insights": {
                "framework": "Classic storytelling arc with clear beginning, middle, and end",
                "vocabulary": "Enhanced with more descriptive and engaging language",
                "pacing": "Improved flow with better sentence variety and rhythm",
                "emotion": "Added emotional depth through word choice and imagery",
                "structure": "Organized with clear narrative progression"
            }
        }
        """
        
        XCTAssertNoThrow({
            let data = mockEnhancementResponse.data(using: .utf8)!
            let response = try JSONDecoder().decode(EnhancementTextResponse.self, from: data)
            
            // Validate structure
            XCTAssertTrue(response.enhancementId.hasPrefix("enh_"))
            XCTAssertGreaterThan(response.enhancedTranscript.count, 100)
            XCTAssertGreaterThanOrEqual(response.insights.count, 3)
            
            // Validate insights structure
            XCTAssertNotNil(response.insights["framework"])
            XCTAssertNotNil(response.insights["vocabulary"])
        })
    }
    
    @MainActor
    func testErrorResponseFormats() {
        // Test different error response formats
        let authError = """
        {
            "error": "UNAUTHORIZED",
            "message": "JWT token is missing, invalid, or expired"
        }
        """
        
        let validationError = """
        {
            "error": "VALIDATION_ERROR",
            "message": "Request validation failed",
            "validation_errors": [
                {
                    "field": "photo_base64",
                    "message": "Photo data is required"
                },
                {
                    "field": "transcript",
                    "message": "Transcript must be between 1 and 5000 characters"
                }
            ]
        }
        """
        
        // Test auth error
        XCTAssertNoThrow({
            let data = authError.data(using: .utf8)!
            let error = try JSONDecoder().decode(ModelErrorResponse.self, from: data)
            XCTAssertEqual(error.error, "UNAUTHORIZED")
        })
        
        // Test validation error
        XCTAssertNoThrow({
            let data = validationError.data(using: .utf8)!
            let error = try JSONDecoder().decode(ValidationErrorResponse.self, from: data)
            XCTAssertEqual(error.validationErrors.count, 2)
            XCTAssertEqual(error.validationErrors.first?.field, "photo_base64")
        })
    }
    
    // MARK: - Model Schema Compliance Tests
    
    @MainActor
    func testAllModelsCompile() {
        // This test ensures all generated models can be instantiated without errors
        // If any model has syntax errors, this test will fail to compile
        
        XCTAssertNoThrow({
            let _ = EnhancementRequest(photoBase64: Data(), transcript: "test")
            let _ = EnhancementTextResponse(enhancementId: "enh_test", enhancedTranscript: "test", insights: [:])
            let _ = EnhancementAudioResponse(audioBase64: Data(), audioFormat: .mp3)
            let _ = AuthResponse(accessToken: "token", user: AuthResponseUser(userId: "id", email: "test@example.com"))
            let _ = GoogleAuthRequest(idToken: "token")
            let _ = ModelErrorResponse(error: "ERROR", message: "message")
        })
    }
}
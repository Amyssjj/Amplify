//
//  ModelMapperTests.swift
//  AmplifyAPITests
//
//  Tests for model mapping between API and app models
//

import Foundation
import XCTest

@testable import Amplify

class ModelMapperTests: XCTestCase {

    var mapperService: ModelMapperService!

    @MainActor
    override func setUp() {
        super.setUp()
        mapperService = ModelMapperService()
    }

    @MainActor
    override func tearDown() {
        mapperService = nil
        super.tearDown()
    }

    // MARK: - Enhancement Mapping Tests

    @MainActor
    func testMapEnhancementResponseToRecording() async throws {
        // Setup
        let originalRecording = Recording(
            id: UUID(),
            transcript: "Original story text",
            duration: 30.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let enhancementResponse = EnhancementTextResponse(
            enhancementId: "enh_123456",
            enhancedTranscript: "This is an enhanced and improved story with better vocabulary.",
            insights: [
                "framework": "Clear narrative structure with strong beginning and end",
                "vocabulary": "Rich, descriptive language enhances the storytelling",
                "pacing": "Good rhythm and flow throughout the narrative",
            ]
        )

        // Execute
        let updatedRecording = await mapperService.mapEnhancementResponse(
            enhancementResponse,
            to: originalRecording
        )

        // Verify
        XCTAssertEqual(
            updatedRecording.enhancedTranscript,
            "This is an enhanced and improved story with better vocabulary.")
        XCTAssertEqual(updatedRecording.insights.count, 3)

        // Verify insight categories mapped correctly
        let categories = updatedRecording.insights.map { $0.category }
        XCTAssertTrue(categories.contains(.framework))
        XCTAssertTrue(categories.contains(.vocabulary))
        XCTAssertTrue(categories.contains(.pacing))

        // Verify insight content
        let frameworkInsight = updatedRecording.insights.first { $0.category == .framework }
        XCTAssertNotNil(frameworkInsight)
        XCTAssertEqual(
            frameworkInsight?.description, "Clear narrative structure with strong beginning and end"
        )
    }

    @MainActor
    func testMapEnhancementDetailsToRecording() async throws {
        // Setup
        let originalRecording = Recording(
            id: UUID(),
            transcript: "Original text",
            duration: 25.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let enhancementDetails = EnhancementDetails(
            enhancementId: "enh_789",
            createdAt: Date(),
            originalTranscript: "Original text",
            enhancedTranscript: "Enhanced and detailed story",
            insights: [
                "structure": "Well-organized narrative flow",
                "emotion": "Strong emotional impact",
            ],
            audioStatus: .ready,
            photoBase64: nil
        )

        // Execute
        let updatedRecording = await mapperService.mapEnhancementDetails(
            enhancementDetails,
            to: originalRecording
        )

        // Verify
        XCTAssertEqual(updatedRecording.enhancedTranscript, "Enhanced and detailed story")
        XCTAssertEqual(updatedRecording.insights.count, 2)

        let emotionInsight = updatedRecording.insights.first { $0.category == .emotion }
        XCTAssertNotNil(emotionInsight)
        XCTAssertEqual(emotionInsight?.description, "Strong emotional impact")
    }

    @MainActor
    func testCreateEnhancementRequestFromRecording() {
        // Setup
        let recording = Recording(
            id: UUID(),
            transcript: "Test story content",
            duration: 20.0,
            photoURL: "test.jpg",
            timestamp: Date()
        )

        let photoData = "test_photo_data".data(using: .utf8)!

        // Execute
        let request = mapperService.createEnhancementRequest(
            from: recording,
            with: photoData
        )

        // Verify
        XCTAssertEqual(request.transcript, "Test story content")
        XCTAssertEqual(request.photoBase64, photoData.base64EncodedString())
        XCTAssertEqual(request.language, "en")
    }

    // MARK: - Insight Mapping Tests

    @MainActor
    func testInsightCategoryMapping() async {
        // Setup
        let recording = Recording(
            id: UUID(),
            transcript: "Test",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let response = EnhancementTextResponse(
            enhancementId: "enh_test",
            enhancedTranscript: "Enhanced text",
            insights: [
                "framework": "Framework insight",
                "vocabulary": "Vocabulary insight",
                "technique": "Technique insight",
                "pacing": "Pacing insight",
                "structure": "Structure insight",
                "engagement": "Engagement insight",
                "clarity": "Clarity insight",
                "emotion": "Emotion insight",
            ]
        )

        // Execute
        let updated = await mapperService.mapEnhancementResponse(response, to: recording)

        // Verify all categories mapped
        XCTAssertEqual(updated.insights.count, 8)

        let categories = Set(updated.insights.map { $0.category })
        XCTAssertTrue(categories.contains(.framework))
        XCTAssertTrue(categories.contains(.vocabulary))
        XCTAssertTrue(categories.contains(.technique))
        XCTAssertTrue(categories.contains(.pacing))
        XCTAssertTrue(categories.contains(.structure))
        XCTAssertTrue(categories.contains(.engagement))
        XCTAssertTrue(categories.contains(.clarity))
        XCTAssertTrue(categories.contains(.emotion))
    }

    @MainActor
    func testInsightTitleGeneration() async {
        // Setup
        let recording = Recording(
            id: UUID(),
            transcript: "Test",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        let response = EnhancementTextResponse(
            enhancementId: "enh_test",
            enhancedTranscript: "Enhanced",
            insights: [
                "vocabulary": "Strong and excellent word choices",
                "pacing": "Consider improving the rhythm",
                "clarity": "Weak clarity in some sections",
            ]
        )

        // Execute
        let updated = await mapperService.mapEnhancementResponse(response, to: recording)

        // Verify titles generated correctly
        let vocabInsight = updated.insights.first { $0.category == .vocabulary }
        XCTAssertTrue(vocabInsight?.title.contains("Strength") ?? false)

        let pacingInsight = updated.insights.first { $0.category == .pacing }
        XCTAssertTrue(pacingInsight?.title.contains("Opportunity") ?? false)

        let clarityInsight = updated.insights.first { $0.category == .clarity }
        XCTAssertTrue(clarityInsight?.title.contains("Opportunity") ?? false)
    }

    // MARK: - User Mapping Tests

    @MainActor
    func testMapAuthResponseToUser() {
        // Setup
        let authResponse = AuthResponse(
            accessToken: "jwt_token",
            tokenType: .bearer,
            expiresIn: 3600,
            user: AuthResponseUser(
                userId: "user_123",
                email: "test@example.com",
                name: "Test User",
                picture: "https://example.com/avatar.jpg"
            )
        )

        // Execute
        let user = mapperService.mapAuthenticationResponse(authResponse)

        // Verify
        XCTAssertEqual(user.id, "user_123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.profileImageURL, "https://example.com/avatar.jpg")
    }

    @MainActor
    func testUserDisplayProperties() {
        // Setup
        let authUser = AuthResponseUser(
            userId: "user_456",
            email: "john.doe@example.com",
            name: "John Doe",
            picture: nil
        )

        let user = User(from: authUser)

        // Verify display properties
        XCTAssertEqual(user.displayName, "John Doe")
        XCTAssertEqual(user.initials, "JD")
        XCTAssertFalse(user.hasProfileImage)

        // Test user without name
        let authUserNoName = AuthResponseUser(
            userId: "user_789",
            email: "jane@example.com",
            name: nil,
            picture: nil
        )

        let userNoName = User(from: authUserNoName)
        XCTAssertEqual(userNoName.displayName, "jane")
        XCTAssertEqual(userNoName.initials, "JA")
    }

    // MARK: - Historical Data Mapping Tests

    @MainActor
    func testMapHistoricalEnhancements() {
        // Setup
        let summary1 = EnhancementSummary(
            enhancementId: "enh_001",
            createdAt: Date(),
            transcriptPreview: "Preview of first story...",
            audioStatus: .ready
        )

        let summary2 = EnhancementSummary(
            enhancementId: "enh_002",
            createdAt: Date().addingTimeInterval(-3600),
            transcriptPreview: "Preview of second story...",
            audioStatus: .notGenerated
        )

        let response = GetEnhancements200Response(
            total: 2,
            items: [summary1, summary2]
        )

        // Execute
        let recordings = mapperService.mapHistoricalEnhancements(response)

        // Verify
        XCTAssertEqual(recordings.count, 2)
        XCTAssertEqual(recordings[0].transcript, "Preview of first story...")
        XCTAssertEqual(recordings[1].transcript, "Preview of second story...")
    }

    // MARK: - Validation Tests

    @MainActor
    func testValidateEnhancementResponse() {
        // Valid response
        let validResponse = EnhancementTextResponse(
            enhancementId: "enh_123",
            enhancedTranscript: "Enhanced content",
            insights: ["key": "value"]
        )

        XCTAssertTrue(mapperService.validateEnhancementResponse(validResponse))

        // Invalid responses
        let invalidResponse1 = EnhancementTextResponse(
            enhancementId: "",
            enhancedTranscript: "Enhanced content",
            insights: [:]
        )

        XCTAssertFalse(mapperService.validateEnhancementResponse(invalidResponse1))

        let invalidResponse2 = EnhancementTextResponse(
            enhancementId: "enh_123",
            enhancedTranscript: "",
            insights: [:]
        )

        XCTAssertFalse(mapperService.validateEnhancementResponse(invalidResponse2))
    }

    @MainActor
    func testValidateInsights() {
        // Valid insights
        let validInsights = [
            "framework": "Good structure",
            "vocabulary": "Rich language",
        ]

        XCTAssertTrue(mapperService.hasValidInsights(validInsights))

        // Invalid insights
        XCTAssertFalse(mapperService.hasValidInsights([:]))
        XCTAssertFalse(mapperService.hasValidInsights(["key": ""]))
        XCTAssertFalse(mapperService.hasValidInsights(["key": "   "]))
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testSafelyMapEnhancementWithError() async {
        // Setup
        let recording = Recording(
            id: UUID(),
            transcript: "Test",
            duration: 10.0,
            photoURL: "photo.jpg",
            timestamp: Date()
        )

        // Test nil response
        do {
            _ = try await mapperService.safelyMapEnhancement(nil, to: recording)
            XCTFail("Expected error for nil response")
        } catch let error as ModelMapperService.MappingError {
            if case .invalidEnhancementResponse = error {
                // Expected error
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Unexpected error type")
        }

        // Test invalid response
        let invalidResponse = EnhancementTextResponse(
            enhancementId: "",
            enhancedTranscript: "",
            insights: [:]
        )

        do {
            _ = try await mapperService.safelyMapEnhancement(invalidResponse, to: recording)
            XCTFail("Expected error for invalid response")
        } catch let error as ModelMapperService.MappingError {
            if case .invalidEnhancementResponse = error {
                // Expected error
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    // MARK: - Audio Response Tests

    @MainActor
    func testProcessAudioResponse() {
        // Setup
        let audioData = "fake_audio_data".data(using: .utf8)!
        let audioResponse = EnhancementAudioResponse(
            audioBase64: audioData,
            audioFormat: .mp3
        )

        // Execute
        let processedData = mapperService.processAudioResponse(audioResponse)

        // Verify
        XCTAssertEqual(processedData, audioData)
    }
}

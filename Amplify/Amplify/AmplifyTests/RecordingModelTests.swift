//
//  RecordingModelTests.swift
//  AmplifyTests
//
//  Test-Driven Development for Recording Data Model
//

import XCTest

@testable import Amplify

class RecordingModelTests: XCTestCase {

    @MainActor
    func testRecordingInitialization() {
        // Given
        let id = UUID()
        let transcript = "This is a beautiful sunset over the mountains"
        let duration = 45.5
        let photoURL = "test-photo-url"
        let timestamp = Date()

        // When
        let recording = Recording(
            id: id,
            transcript: transcript,
            duration: duration,
            photoURL: photoURL,
            timestamp: timestamp
        )

        // Then
        XCTAssertEqual(recording.id, id)
        XCTAssertEqual(recording.transcript, transcript)
        XCTAssertEqual(recording.duration, duration, accuracy: 0.1)
        XCTAssertEqual(recording.photoURL, photoURL)
        XCTAssertEqual(recording.timestamp, timestamp)
    }

    @MainActor
    func testRecordingWithEnhancedTranscript() {
        // Given
        let originalTranscript = "nice sunset"
        let enhancedTranscript = "breathtaking sunset"
        let recording = Recording(
            id: UUID(),
            transcript: originalTranscript,
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )

        // When
        recording.setEnhancedTranscript(enhancedTranscript)

        // Then
        XCTAssertEqual(recording.enhancedTranscript, enhancedTranscript)
        XCTAssertEqual(recording.originalTranscript, originalTranscript)
    }

    @MainActor
    func testRecordingAddInsight() {
        // Given
        let recording = Recording(
            id: UUID(),
            transcript: "test transcript",
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )
        let insight = AIInsight(
            id: UUID(),
            title: "STAR Method",
            category: .framework,
            description: "Story follows STAR structure",
            suggestion: "Continue using this framework"
        )

        // When
        recording.addInsight(insight)

        // Then
        XCTAssertEqual(recording.insights.count, 1)
        XCTAssertEqual(recording.insights.first?.title, "STAR Method")
    }

    @MainActor
    func testRecordingWordHighlights() {
        // Given
        let recording = Recording(
            id: UUID(),
            transcript: "This is a beautiful sunset",
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )
        let highlights = [
            WordHighlight(word: "beautiful", timestamp: 2.5, suggested: "breathtaking"),
            WordHighlight(word: "sunset", timestamp: 4.0, suggested: nil),
        ]

        // When
        recording.setWordHighlights(highlights)

        // Then
        XCTAssertEqual(recording.wordHighlights.count, 2)
        XCTAssertEqual(recording.wordHighlights[0].word, "beautiful")
        XCTAssertEqual(recording.wordHighlights[0].suggested, "breathtaking")
        XCTAssertNil(recording.wordHighlights[1].suggested)
    }

    @MainActor
    func testRecordingEquality() {
        // Given
        let id = UUID()
        let recording1 = Recording(
            id: id,
            transcript: "test",
            duration: 30.0,
            photoURL: "url",
            timestamp: Date()
        )
        let recording2 = Recording(
            id: id,
            transcript: "different transcript",
            duration: 45.0,
            photoURL: "different url",
            timestamp: Date()
        )
        let recording3 = Recording(
            id: UUID(),
            transcript: "test",
            duration: 30.0,
            photoURL: "url",
            timestamp: Date()
        )

        // Then
        XCTAssertEqual(recording1, recording2)  // Same ID
        XCTAssertNotEqual(recording1, recording3)  // Different ID
    }

    // MARK: - Enhanced Recording Tests

    @MainActor
    func testSetEnhancementId() {
        // Given
        let recording = Recording(
            id: UUID(),
            transcript: "test transcript",
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )
        let enhancementId = "enhancement-123"

        // When
        recording.setEnhancementId(enhancementId)

        // Then
        XCTAssertEqual(recording.enhancementId, enhancementId)
    }

    @MainActor
    func testAddDuplicateInsightPrevention() {
        // Given
        let recording = Recording(
            id: UUID(),
            transcript: "test transcript",
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )
        let insightId = UUID()
        let insight1 = AIInsight(
            id: insightId,
            title: "STAR Method",
            category: .framework,
            description: "Story follows STAR structure",
            suggestion: "Continue using this framework"
        )
        let insight2 = AIInsight(
            id: insightId,  // Same ID as insight1
            title: "Different Title",
            category: .clarity,
            description: "Different description",
            suggestion: "Different suggestion"
        )

        // When
        recording.addInsight(insight1)
        recording.addInsight(insight2)  // Should be rejected as duplicate

        // Then
        XCTAssertEqual(recording.insights.count, 1)
        XCTAssertEqual(recording.insights.first?.title, "STAR Method")  // Original insight preserved
    }

    @MainActor
    func testOriginalTranscriptProperty() {
        // Given
        let originalText = "This is the original transcript"
        let recording = Recording(
            id: UUID(),
            transcript: originalText,
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )

        // When
        recording.setEnhancedTranscript("This is the enhanced version")

        // Then
        XCTAssertEqual(recording.originalTranscript, originalText)
        XCTAssertEqual(recording.transcript, originalText)  // transcript property should remain unchanged
        XCTAssertEqual(recording.enhancedTranscript, "This is the enhanced version")
    }

    @MainActor
    func testMultipleInsights() {
        // Given
        let recording = Recording(
            id: UUID(),
            transcript: "test transcript",
            duration: 30.0,
            photoURL: "test-url",
            timestamp: Date()
        )
        let insight1 = AIInsight(
            id: UUID(),
            title: "STAR Method",
            category: .framework,
            description: "Story follows STAR structure",
            suggestion: "Continue using this framework"
        )
        let insight2 = AIInsight(
            id: UUID(),
            title: "Clarity",
            category: .clarity,
            description: "Story is very clear",
            suggestion: "Maintain this clarity"
        )

        // When
        recording.addInsight(insight1)
        recording.addInsight(insight2)

        // Then
        XCTAssertEqual(recording.insights.count, 2)
        XCTAssertTrue(recording.insights.contains { $0.title == "STAR Method" })
        XCTAssertTrue(recording.insights.contains { $0.title == "Clarity" })
    }
}

// MARK: - WordHighlight Tests

extension RecordingModelTests {

    func testWordHighlightInitialization() {
        // Given
        let word = "beautiful"
        let timestamp = 2.5
        let suggested = "breathtaking"

        // When
        let highlight = WordHighlight(word: word, timestamp: timestamp, suggested: suggested)

        // Then
        XCTAssertEqual(highlight.word, word)
        XCTAssertEqual(highlight.timestamp, timestamp)
        XCTAssertEqual(highlight.suggested, suggested)
        XCTAssertNotNil(highlight.id)  // Should have auto-generated UUID
    }

    func testWordHighlightWithoutSuggestion() {
        // Given
        let word = "sunset"
        let timestamp = 4.0

        // When
        let highlight = WordHighlight(word: word, timestamp: timestamp)

        // Then
        XCTAssertEqual(highlight.word, word)
        XCTAssertEqual(highlight.timestamp, timestamp)
        XCTAssertNil(highlight.suggested)
        XCTAssertNotNil(highlight.id)
    }
}

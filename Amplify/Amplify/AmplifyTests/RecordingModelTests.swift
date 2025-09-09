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
            WordHighlight(word: "sunset", timestamp: 4.0, suggested: nil)
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
        XCTAssertEqual(recording1, recording2) // Same ID
        XCTAssertNotEqual(recording1, recording3) // Different ID
    }
}
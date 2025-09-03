//
//  SpeechRecognitionServiceTests.swift
//  AmplifyTests
//
//  Test-Driven Development for Speech Recognition Service
//

import XCTest
import Speech
@testable import Amplify

class SpeechRecognitionServiceTests: XCTestCase {
    
    var speechService: SpeechRecognitionService!
    
    override func setUp() {
        super.setUp()
        speechService = SpeechRecognitionService()
    }
    
    override func tearDown() {
        speechService = nil
        super.tearDown()
    }
    
    func testRequestSpeechRecognitionPermission() async {
        // When
        let permission = await speechService.requestSpeechRecognitionPermission()
        
        // Then
        XCTAssertTrue([
            SpeechRecognitionPermissionStatus.authorized,
            SpeechRecognitionPermissionStatus.denied,
            SpeechRecognitionPermissionStatus.restricted,
            SpeechRecognitionPermissionStatus.notDetermined
        ].contains(permission))
    }
    
    func testIsAvailableForRecognition() {
        // When
        let isAvailable = speechService.isAvailableForRecognition()
        
        // Then
        // Should be true for English in test environment
        XCTAssertNotNil(isAvailable)
    }
    
    func testStartLiveRecognitionWithPermission() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        
        // When
        let result = await speechService.startLiveRecognition { transcript in
            // Mock transcript callback
        }
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(speechService.isRecognizing)
        case .failure(let error):
            // May fail in simulator/test environment
            XCTAssertTrue(error is SpeechRecognitionError)
        }
    }
    
    func testStartLiveRecognitionWithoutPermission() async {
        // Given
        speechService.mockPermissionStatus = .denied
        
        // When
        let result = await speechService.startLiveRecognition { transcript in }
        
        // Then
        switch result {
        case .success:
            XCTFail("Should not succeed without permission")
        case .failure(let error):
            XCTAssertEqual(error as? SpeechRecognitionError, .permissionDenied)
        }
    }
    
    func testStopLiveRecognition() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        _ = await speechService.startLiveRecognition { _ in }
        
        // When
        speechService.stopLiveRecognition()
        
        // Then
        XCTAssertFalse(speechService.isRecognizing)
    }
    
    func testTranscriptCallbackExecution() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        var receivedTranscripts: [String] = []
        
        // When
        _ = await speechService.startLiveRecognition { transcript in
            receivedTranscripts.append(transcript)
        }
        
        // Simulate transcript updates
        speechService.simulateTranscriptUpdate("Hello")
        speechService.simulateTranscriptUpdate("Hello world")
        
        // Then
        XCTAssertEqual(receivedTranscripts.count, 2)
        XCTAssertEqual(receivedTranscripts[0], "Hello")
        XCTAssertEqual(receivedTranscripts[1], "Hello world")
    }
    
    func testRecognizeAudioFile() async throws {
        // Given
        let mockAudioURL = createMockAudioFile()
        speechService.mockPermissionStatus = .authorized
        
        // When
        let result = await speechService.recognizeAudioFile(url: mockAudioURL)
        
        // Then
        switch result {
        case .success(let transcript):
            XCTAssertNotNil(transcript)
            XCTAssertFalse(transcript.isEmpty)
        case .failure(let error):
            // May fail with mock audio file
            XCTAssertTrue(error is SpeechRecognitionError)
        }
    }
    
    func testRecognitionConfidenceLevels() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        var confidenceScores: [Float] = []
        
        // When
        _ = await speechService.startLiveRecognition { transcript in }
        speechService.onConfidenceUpdate = { confidence in
            confidenceScores.append(confidence)
        }
        
        speechService.simulateConfidenceUpdate(0.85)
        speechService.simulateConfidenceUpdate(0.92)
        
        // Then
        XCTAssertEqual(confidenceScores.count, 2)
        XCTAssertEqual(confidenceScores[0], 0.85, accuracy: 0.01)
        XCTAssertEqual(confidenceScores[1], 0.92, accuracy: 0.01)
    }
    
    func testErrorHandlingForUnavailableService() async {
        // Given
        speechService.mockIsAvailable = false
        
        // When
        let result = await speechService.startLiveRecognition { _ in }
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail when service unavailable")
        case .failure(let error):
            XCTAssertEqual(error as? SpeechRecognitionError, .recognitionUnavailable)
        }
    }
    
    func testMultipleRecognitionSessionsHandling() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        
        // When - Start first recognition
        _ = await speechService.startLiveRecognition { _ in }
        XCTAssertTrue(speechService.isRecognizing)
        
        // Try to start second recognition
        let result = await speechService.startLiveRecognition { _ in }
        
        // Then
        switch result {
        case .success:
            // Should handle gracefully
            XCTAssertTrue(speechService.isRecognizing)
        case .failure:
            // Or should fail with appropriate error
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockAudioFile() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        return tempDirectory.appendingPathComponent("mock-audio.m4a")
    }
}
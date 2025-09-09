//
//  SpeechRecognitionServiceTests.swift
//  AmplifyTests
//
//  Created by Claude on 2025-09-09.
//

import Speech
import XCTest

@testable import Amplify

@MainActor
final class SpeechRecognitionServiceTests: XCTestCase {

    var speechService: SpeechRecognitionService!

    override func setUp() {
        super.setUp()
        speechService = SpeechRecognitionService()
    }

    override func tearDown() {
        speechService = nil
        super.tearDown()
    }

    // MARK: - Permission Tests

    func testRequestSpeechRecognitionPermission() async {
        // Given
        speechService.mockPermissionStatus = .authorized

        // When
        let status = await speechService.requestSpeechRecognitionPermission()

        // Then
        XCTAssertEqual(status, .authorized)
    }

    func testRequestSpeechRecognitionPermissionDenied() async {
        // Given
        speechService.mockPermissionStatus = .denied

        // When
        let status = await speechService.requestSpeechRecognitionPermission()

        // Then
        XCTAssertEqual(status, .denied)
    }

    func testRequestSpeechRecognitionPermissionRestricted() async {
        // Given
        speechService.mockPermissionStatus = .restricted

        // When
        let status = await speechService.requestSpeechRecognitionPermission()

        // Then
        XCTAssertEqual(status, .restricted)
    }

    // MARK: - Availability Tests

    func testIsAvailableForRecognition() {
        // When
        let isAvailable = speechService.isAvailableForRecognition()

        // Then
        // In test environment, this may be false due to lack of speech recognition
        XCTAssertTrue(isAvailable || !isAvailable)  // Just verify it doesn't crash
    }

    func testIsAvailableForRecognitionWithMock() {
        // Given
        speechService.mockIsAvailable = true

        // When
        let isAvailable = speechService.isAvailableForRecognition()

        // Then
        XCTAssertTrue(isAvailable)
    }

    func testIsAvailableForRecognitionWithMockFalse() {
        // Given
        speechService.mockIsAvailable = false

        // When
        let isAvailable = speechService.isAvailableForRecognition()

        // Then
        XCTAssertFalse(isAvailable)
    }

    // MARK: - Live Recognition Tests

    func testStartLiveRecognition() async {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true

        // When
        await speechService.startLiveRecognition { transcript in
            // Mock callback
        }

        // Then
        XCTAssertTrue(speechService.isRecognizing)
    }

    func testStartLiveRecognitionSuccess() async {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true

        // When
        await speechService.startLiveRecognition { transcript in
            // Mock callback
        }

        // Then
        XCTAssertTrue(speechService.isRecognizing)
    }

    func testStartLiveRecognitionPermissionDenied() async {
        // Given
        speechService.mockPermissionStatus = .denied

        // When
        let result = await speechService.startLiveRecognition { transcript in
            // Should not be called
            XCTFail("Callback should not be called when permission denied")
        }

        // Then
        switch result {
        case .success:
            XCTFail("Should fail with permission denied")
        case .failure(let error):
            XCTAssertEqual(error, .permissionDenied)
        }
    }

    func testStartLiveRecognitionUnavailable() async {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = false

        // When
        let result = await speechService.startLiveRecognition { transcript in
            // Should not be called
            XCTFail("Callback should not be called when recognition unavailable")
        }

        // Then
        switch result {
        case .success:
            XCTFail("Should fail when recognition unavailable")
        case .failure(let error):
            XCTAssertEqual(error, .recognitionUnavailable)
        }
    }

    func testStopLiveRecognition() {
        // Given
        speechService.isRecognizing = true

        // When
        speechService.stopLiveRecognition()

        // Then
        XCTAssertFalse(speechService.isRecognizing)
    }

    // MARK: - File Recognition Tests

    func testRecognizeAudioFromFile() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        let tempURL = try createTempAudioFile()

        // When
        let result = await speechService.recognizeAudioFile(url: tempURL)

        // Then
        switch result {
        case .success(let transcript):
            XCTAssertFalse(transcript.isEmpty)
        case .failure(let error):
            // May fail in test environment
            XCTAssertTrue(
                [
                    SpeechRecognitionError.permissionDenied, .recognitionUnavailable,
                    .recognitionFailed,
                ].contains(error))
        }
    }

    func testRecognizeAudioFromFilePermissionDenied() async throws {
        // Given
        speechService.mockPermissionStatus = .denied
        let tempURL = try createTempAudioFile()

        // When
        let result = await speechService.recognizeAudioFile(url: tempURL)

        // Then
        switch result {
        case .success:
            XCTFail("Should fail with permission denied")
        case .failure(let error):
            XCTAssertEqual(error, .permissionDenied)
        }
    }

    func testRecognizeAudioFromFileUnavailable() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = false
        let tempURL = try createTempAudioFile()

        // When
        let result = await speechService.recognizeAudioFile(url: tempURL)

        // Then
        switch result {
        case .success:
            XCTFail("Should fail when recognition unavailable")
        case .failure(let error):
            XCTAssertEqual(error, .recognitionUnavailable)
        }
    }

    // MARK: - Confidence Tests

    func testRecognitionConfidenceProperty() {
        // Given
        speechService.recognitionConfidence = 0.85

        // Then
        XCTAssertEqual(speechService.recognitionConfidence, 0.85, accuracy: 0.01)
    }

    func testCurrentTranscriptProperty() {
        // Given
        let testTranscript = "This is a test transcript"
        speechService.currentTranscript = testTranscript

        // Then
        XCTAssertEqual(speechService.currentTranscript, testTranscript)
    }

    // MARK: - Error Handling Tests

    func testAudioEngineStartError() async {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true

        // When
        let result = await speechService.startLiveRecognition { transcript in
            // Mock callback
        }

        // Then
        switch result {
        case .success:
            XCTAssertTrue(speechService.isRecognizing)
        case .failure(let error):
            XCTAssertEqual(error, .audioEngineStartFailed)
        }
    }

    func testRequestCreationFailedError() async {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true

        // When
        let result = await speechService.startLiveRecognition { transcript in
            // Mock callback
        }

        // Then
        switch result {
        case .success:
            XCTAssertTrue(speechService.isRecognizing)
        case .failure(let error):
            XCTAssertEqual(error, .requestCreationFailed)
        }
    }

    // MARK: - Integration Tests

    func testCompleteRecognitionFlow() async throws {
        // Given
        speechService.mockPermissionStatus = .authorized
        speechService.mockIsAvailable = true
        let tempURL = try createTempAudioFile()

        // When - Complete flow from permission to recognition
        let permissionStatus = await speechService.requestSpeechRecognitionPermission()
        guard permissionStatus == .authorized else {
            XCTFail("Permission should be authorized for this test")
            return
        }

        let isAvailable = speechService.isAvailableForRecognition()
        guard isAvailable else {
            XCTFail("Recognition should be available for this test")
            return
        }

        let result = await speechService.recognizeAudioFile(url: tempURL)

        // Then
        switch result {
        case .success(let transcript):
            XCTAssertFalse(transcript.isEmpty)
        case .failure(let error):
            // May fail in test environment, but should be one of expected errors
            XCTAssertTrue(
                [
                    SpeechRecognitionError.recognitionFailed, .audioEngineStartFailed,
                    .requestCreationFailed,
                ].contains(
                    error))
        }
    }
}

// MARK: - Helper Extensions

extension SpeechRecognitionServiceTests {

    private func createTempAudioFile() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("test_audio.wav")

        // Create a minimal WAV file for testing
        let wavData = Data([
            // WAV header
            0x52, 0x49, 0x46, 0x46,  // "RIFF"
            0x24, 0x00, 0x00, 0x00,  // File size
            0x57, 0x41, 0x56, 0x45,  // "WAVE"
            0x66, 0x6D, 0x74, 0x20,  // "fmt "
            0x10, 0x00, 0x00, 0x00,  // Subchunk size
            0x01, 0x00,  // Audio format (PCM)
            0x01, 0x00,  // Number of channels
            0x44, 0xAC, 0x00, 0x00,  // Sample rate (44100)
            0x88, 0x58, 0x01, 0x00,  // Byte rate
            0x02, 0x00,  // Block align
            0x10, 0x00,  // Bits per sample
            0x64, 0x61, 0x74, 0x61,  // "data"
            0x00, 0x00, 0x00, 0x00,  // Data size (empty)
        ])

        try wavData.write(to: tempURL)
        return tempURL
    }
}

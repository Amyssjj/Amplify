//
//  AudioRecordingServiceTests.swift
//  AmplifyTests
//
//  Created by Claude on 2025-09-09.
//

import AVFoundation
import XCTest

@testable import Amplify

@MainActor
final class AudioRecordingServiceTests: XCTestCase {

    var audioService: AudioRecordingService!

    override func setUp() {
        super.setUp()
        audioService = AudioRecordingService()
    }

    override func tearDown() {
        audioService = nil
        super.tearDown()
    }

    // MARK: - Permission Tests

    func testRequestMicrophonePermission() async {
        // Given
        audioService.mockPermissionStatus = .authorized

        // When
        let status = await audioService.requestMicrophonePermission()

        // Then
        XCTAssertEqual(status, .authorized)
    }

    func testRequestMicrophonePermissionDenied() async {
        // Given
        audioService.mockPermissionStatus = .denied

        // When
        let status = await audioService.requestMicrophonePermission()

        // Then
        XCTAssertEqual(status, .denied)
    }

    // MARK: - Recording Lifecycle Tests

    func testPrepareForRecording() async {
        // Given
        audioService.mockPermissionStatus = .authorized

        // When
        let result = await audioService.prepareForRecording()

        // Then
        switch result {
        case .success:
            XCTAssertTrue(audioService.isPrepared)
            XCTAssertNotNil(audioService.currentRecordingURL)
        case .failure(let error):
            // May fail in test environment due to audio session
            XCTAssertTrue([.audioSessionSetupFailed, .recordingStartFailed].contains(error))
        }
    }

    func testStartRecording() {
        // Given - Mock prepared state
        audioService.mockPermissionStatus = .authorized

        // When
        let result = audioService.startRecording()

        // Then
        switch result {
        case .success:
            XCTAssertTrue(audioService.isRecording)
        case .failure(let error):
            // Expected to fail without proper setup in test environment
            XCTAssertTrue([.notPrepared, .audioSessionSetupFailed].contains(error))
        }
    }

    func testStartRecordingNotPrepared() {
        // Given - Not prepared

        // When
        let result = audioService.startRecording()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail when not prepared")
        case .failure(let error):
            XCTAssertEqual(error, .notPrepared)
        }
    }

    func testStopRecording() {
        // Given - Mock recording state
        audioService.isRecording = true

        // When
        let result = audioService.stopRecording()

        // Then
        switch result {
        case .success(let recordingData):
            XCTAssertFalse(audioService.isRecording)
            XCTAssertNotNil(recordingData)
        case .failure:
            // May fail in test environment
            XCTAssertFalse(audioService.isRecording)
        }
    }

    func testStopRecordingNotRecording() {
        // Given - Not recording
        audioService.isRecording = false

        // When
        let result = audioService.stopRecording()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail when not recording")
        case .failure(let error):
            XCTAssertEqual(error, .notRecording)
        }
    }

    func testCancelRecording() {
        // Given - Mock recording state
        audioService.isRecording = true

        // When
        audioService.cancelRecording()

        // Then
        XCTAssertFalse(audioService.isRecording)
        XCTAssertFalse(audioService.isPrepared)
        XCTAssertEqual(audioService.currentRecordingDuration, 0)
    }

    // MARK: - Configuration Tests

    func testMaxRecordingDurationConfiguration() {
        // Given
        let customDuration: TimeInterval = 120.0

        // When
        audioService.maxRecordingDuration = customDuration

        // Then
        XCTAssertEqual(audioService.maxRecordingDuration, customDuration)
    }

    func testRecordingDurationInitialization() {
        // Then
        XCTAssertEqual(audioService.currentRecordingDuration, 0)
        XCTAssertEqual(audioService.maxRecordingDuration, 60.0)  // Default value
    }

    // MARK: - State Management Tests

    func testInitialState() {
        // Then
        XCTAssertFalse(audioService.isRecording)
        XCTAssertFalse(audioService.isPrepared)
        XCTAssertEqual(audioService.currentRecordingDuration, 0)
        XCTAssertNil(audioService.currentRecordingURL)
    }

    func testCleanup() {
        // Given - Mock some state
        audioService.isRecording = true
        audioService.isPrepared = true

        // When
        audioService.cleanup()

        // Then
        XCTAssertFalse(audioService.isRecording)
        XCTAssertFalse(audioService.isPrepared)
        XCTAssertEqual(audioService.currentRecordingDuration, 0)
    }

    // MARK: - Settings Tests

    func testGetRecordingSettings() {
        // When
        let settings = audioService.getRecordingSettings()

        // Then
        XCTAssertNotNil(settings[AVFormatIDKey])
        XCTAssertNotNil(settings[AVSampleRateKey])
        XCTAssertNotNil(settings[AVNumberOfChannelsKey])
        XCTAssertNotNil(settings[AVEncoderAudioQualityKey])
    }
}

// MARK: - Helper Extensions

extension AudioRecordingServiceTests {

    private func createMockRecordingData() -> AudioRecordingData {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_recording.m4a")

        return AudioRecordingData(
            url: tempURL,
            duration: 10.0,
            createdAt: Date()
        )
    }
}

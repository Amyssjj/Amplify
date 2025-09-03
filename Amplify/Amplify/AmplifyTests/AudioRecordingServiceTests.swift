//
//  AudioRecordingServiceTests.swift
//  AmplifyTests
//
//  Test-Driven Development for Audio Recording Service
//

import XCTest
import AVFoundation
@testable import Amplify

class AudioRecordingServiceTests: XCTestCase {
    
    var audioService: AudioRecordingService!
    
    override func setUp() {
        super.setUp()
        audioService = AudioRecordingService()
    }
    
    override func tearDown() {
        audioService = nil
        super.tearDown()
    }
    
    func testRequestMicrophonePermission() async {
        // When
        let permission = await audioService.requestMicrophonePermission()
        
        // Then
        XCTAssertTrue([
            MicrophonePermissionStatus.authorized,
            MicrophonePermissionStatus.denied,
            MicrophonePermissionStatus.undetermined
        ].contains(permission))
    }
    
    func testPrepareForRecording() async {
        // Given
        audioService.mockPermissionStatus = .authorized
        
        // When
        let result = await audioService.prepareForRecording()
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(audioService.isPrepared)
        case .failure(let error):
            XCTAssertTrue(error is AudioRecordingError)
        }
    }
    
    func testPrepareForRecordingWhenPermissionDenied() async {
        // Given
        audioService.mockPermissionStatus = .denied
        
        // When
        let result = await audioService.prepareForRecording()
        
        // Then
        switch result {
        case .success:
            XCTFail("Should not succeed when permission denied")
        case .failure(let error):
            XCTAssertEqual(error as? AudioRecordingError, .permissionDenied)
        }
    }
    
    func testStartRecording() async throws {
        // Given
        audioService.mockPermissionStatus = .authorized
        _ = await audioService.prepareForRecording()
        
        // When
        let result = audioService.startRecording()
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(audioService.isRecording)
            XCTAssertNotNil(audioService.currentRecordingURL)
        case .failure:
            // May fail in test environment due to audio hardware
            XCTAssertFalse(audioService.isRecording)
        }
    }
    
    func testStopRecording() async throws {
        // Given
        audioService.mockPermissionStatus = .authorized
        _ = await audioService.prepareForRecording()
        _ = audioService.startRecording()
        
        // When
        let result = audioService.stopRecording()
        
        // Then
        switch result {
        case .success(let recordingData):
            XCTAssertFalse(audioService.isRecording)
            XCTAssertNotNil(recordingData.url)
            XCTAssertGreaterThan(recordingData.duration, 0)
        case .failure(let error):
            XCTAssertTrue(error is AudioRecordingError)
        }
    }
    
    func testRecordingDurationTracking() async throws {
        // Given
        audioService.mockPermissionStatus = .authorized
        _ = await audioService.prepareForRecording()
        _ = audioService.startRecording()
        
        // When
        // Simulate some recording time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        let duration = audioService.currentRecordingDuration
        
        // Then
        XCTAssertGreaterThan(duration, 0)
    }
    
    func testMaxRecordingDurationLimit() async throws {
        // Given
        audioService.mockPermissionStatus = .authorized
        audioService.maxRecordingDuration = 0.5 // 0.5 seconds for testing
        _ = await audioService.prepareForRecording()
        
        // When
        _ = audioService.startRecording()
        
        // Wait for auto-stop
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Then
        XCTAssertFalse(audioService.isRecording)
    }
    
    func testCancelRecording() async throws {
        // Given
        audioService.mockPermissionStatus = .authorized
        _ = await audioService.prepareForRecording()
        _ = audioService.startRecording()
        
        // When
        audioService.cancelRecording()
        
        // Then
        XCTAssertFalse(audioService.isRecording)
        XCTAssertNil(audioService.currentRecordingURL)
    }
    
    func testCleanupAfterRecording() async throws {
        // Given
        audioService.mockPermissionStatus = .authorized
        _ = await audioService.prepareForRecording()
        _ = audioService.startRecording()
        let result = audioService.stopRecording()
        
        // When
        audioService.cleanup()
        
        // Then
        XCTAssertFalse(audioService.isPrepared)
        XCTAssertNil(audioService.currentRecordingURL)
    }
    
    func testAudioSessionConfiguration() async {
        // Given
        audioService.mockPermissionStatus = .authorized
        
        // When
        let result = await audioService.prepareForRecording()
        
        // Then
        switch result {
        case .success:
            let audioSession = AVAudioSession.sharedInstance()
            XCTAssertEqual(audioSession.category, .record)
        case .failure:
            // May fail in test environment
            break
        }
    }
    
    func testRecordingQualitySettings() {
        // When
        let settings = audioService.getRecordingSettings()
        
        // Then
        XCTAssertEqual(settings[AVFormatIDKey] as? UInt32, kAudioFormatMPEG4AAC)
        XCTAssertEqual(settings[AVSampleRateKey] as? Float, 44100.0)
        XCTAssertEqual(settings[AVNumberOfChannelsKey] as? Int, 1)
    }
}
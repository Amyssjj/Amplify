//
//  AppStateManagerTests.swift
//  AmplifyTests
//
//  Test-Driven Development for App State Management
//

import XCTest
@testable import Amplify

class AppStateManagerTests: XCTestCase {
    
    var appState: AppStateManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        appState = AppStateManager()
    }
    
    @MainActor
    override func tearDown() {
        appState = nil
        super.tearDown()
    }
    
    @MainActor
    func testInitialState() {
        // Then
        XCTAssertEqual(appState.currentScreen, .home)
        XCTAssertFalse(appState.isRecording)
        XCTAssertFalse(appState.isProcessing)
        XCTAssertNil(appState.currentRecording)
        XCTAssertNil(appState.currentPhoto)
    }
    
    @MainActor
    func testTransitionToRecordingScreen() {
        // Given
        let photoData = PhotoData(
            image: UIImage(),
            identifier: "test-photo",
            isFromUserLibrary: true
        )
        
        // When
        appState.transitionToRecording(with: photoData)
        
        // Then
        XCTAssertEqual(appState.currentScreen, .recording)
        XCTAssertEqual(appState.currentPhoto?.identifier, "test-photo")
    }
    
    @MainActor
    func testStartRecording() {
        // Given
        let photoData = PhotoData(image: UIImage(), identifier: "test", isFromUserLibrary: true)
        appState.transitionToRecording(with: photoData)
        
        // When
        appState.startRecording()
        
        // Then
        XCTAssertTrue(appState.isRecording)
        XCTAssertNotNil(appState.recordingStartTime)
    }
    
    @MainActor
    func testStopRecording() {
        // Given
        let photoData = PhotoData(image: UIImage(), identifier: "test", isFromUserLibrary: true)
        appState.transitionToRecording(with: photoData)
        appState.startRecording()
        
        let recording = Recording(
            id: UUID(),
            transcript: "Test transcript",
            duration: 30.0,
            photoURL: "test",
            timestamp: Date()
        )
        
        // When
        appState.stopRecording(with: recording)
        
        // Then
        XCTAssertFalse(appState.isRecording)
        XCTAssertEqual(appState.currentScreen, .processing)
        XCTAssertEqual(appState.currentRecording?.transcript, "Test transcript")
        XCTAssertNil(appState.recordingStartTime)
    }
    
    @MainActor
    func testTransitionToResults() async {
        // Given
        let recording = Recording(
            id: UUID(),
            transcript: "Test transcript",
            duration: 30.0,
            photoURL: "test",
            timestamp: Date()
        )
        appState.currentRecording = recording
        appState.currentScreen = .processing
        
        let insights = [
            AIInsight(id: UUID(), title: "Test Insight", category: .vocabulary, description: "Test")
        ]
        
        // When
        await appState.transitionToResults(with: insights)
        
        // Then
        XCTAssertEqual(appState.currentScreen, .results)
        XCTAssertFalse(appState.isProcessing)
        XCTAssertEqual(appState.currentRecording?.insights.count, 1)
    }
    
    @MainActor
    func testReturnToHome() {
        // Given
        appState.currentScreen = .results
        appState.currentRecording = Recording(
            id: UUID(),
            transcript: "Test",
            duration: 30.0,
            photoURL: "test",
            timestamp: Date()
        )
        
        // When
        appState.returnToHome()
        
        // Then
        XCTAssertEqual(appState.currentScreen, .home)
        XCTAssertNil(appState.currentRecording)
        XCTAssertNil(appState.currentPhoto)
        XCTAssertFalse(appState.isRecording)
        XCTAssertFalse(appState.isProcessing)
    }
    
    @MainActor
    func testPermissionStates() {
        // When/Then
        XCTAssertEqual(appState.photoPermissionStatus, .notDetermined)
        XCTAssertEqual(appState.microphonePermissionStatus, .undetermined)
        XCTAssertEqual(appState.speechPermissionStatus, .notDetermined)
        
        // When
        appState.updatePhotoPermissionStatus(.authorized)
        appState.updateMicrophonePermissionStatus(.authorized)
        appState.updateSpeechPermissionStatus(.authorized)
        
        // Then
        XCTAssertEqual(appState.photoPermissionStatus, .authorized)
        XCTAssertEqual(appState.microphonePermissionStatus, .authorized)
        XCTAssertEqual(appState.speechPermissionStatus, .authorized)
        XCTAssertTrue(appState.hasAllPermissions)
    }
    
    @MainActor
    func testPermissionDeniedStates() {
        // When
        appState.updatePhotoPermissionStatus(.denied)
        appState.updateMicrophonePermissionStatus(.denied)
        appState.updateSpeechPermissionStatus(.denied)
        
        // Then
        XCTAssertFalse(appState.hasAllPermissions)
        XCTAssertTrue(appState.hasAnyPermissionDenied)
    }
    
    @MainActor
    func testErrorHandling() {
        // When
        let error = AppError.recordingFailed
        appState.handleError(error)
        
        // Then
        XCTAssertEqual(appState.currentError, error)
        XCTAssertTrue(appState.showingError)
    }
    
    @MainActor
    func testClearError() {
        // Given
        appState.handleError(.recordingFailed)
        
        // When
        appState.clearError()
        
        // Then
        XCTAssertNil(appState.currentError)
        XCTAssertFalse(appState.showingError)
    }
    
    @MainActor
    func testRecordingDurationTracking() {
        // Given
        appState.startRecording()
        let startTime = Date()
        appState.recordingStartTime = startTime
        
        // When
        let duration = appState.currentRecordingDuration
        
        // Then
        XCTAssertGreaterThanOrEqual(duration, 0)
    }
    
    @MainActor
    func testCanRecordState() {
        // Given - No permissions
        XCTAssertFalse(appState.canRecord)
        
        // When - Grant permissions
        appState.updateMicrophonePermissionStatus(.authorized)
        appState.updateSpeechPermissionStatus(.authorized)
        
        // Then
        XCTAssertTrue(appState.canRecord)
        
        // When - Already recording
        appState.isRecording = true
        
        // Then
        XCTAssertFalse(appState.canRecord)
    }
    
    @MainActor
    func testProcessingStateManagement() {
        // When
        appState.setProcessing(true, progress: 0.5)
        
        // Then
        XCTAssertTrue(appState.isProcessing)
        XCTAssertEqual(appState.processingProgress, 0.5, accuracy: 0.01)
        
        // When
        appState.setProcessing(false, progress: 1.0)
        
        // Then
        XCTAssertFalse(appState.isProcessing)
        XCTAssertEqual(appState.processingProgress, 1.0, accuracy: 0.01)
    }
}
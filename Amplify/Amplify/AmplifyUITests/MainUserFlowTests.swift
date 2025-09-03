//
//  MainUserFlowTests.swift
//  AmplifyUITests
//
//  End-to-end UI tests for main user flow
//

import XCTest

class MainUserFlowTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testCompleteStorytellingFlow() throws {
        // Test the complete "Capture, Cook, Comprehend" flow
        
        // MARK: - Home Screen Tests
        
        // Verify home screen elements
        let photoImageView = app.images["StoryPromptPhoto"]
        let recordButton = app.buttons["RecordStoryButton"]
        
        XCTAssertTrue(photoImageView.exists)
        XCTAssertTrue(recordButton.exists)
        
        // Test swipe to refresh photo
        photoImageView.swipeLeft()
        // Allow time for photo to change
        sleep(1)
        
        // MARK: - Recording Screen Tests
        
        // Tap record button to start recording
        recordButton.tap()
        
        // Verify recording screen elements
        let liveTranscriptText = app.staticTexts["LiveTranscript"]
        let stopRecordingButton = app.buttons["StopRecordingButton"]
        let recordingTimer = app.staticTexts["RecordingTimer"]
        
        XCTAssertTrue(liveTranscriptText.exists)
        XCTAssertTrue(stopRecordingButton.exists)
        XCTAssertTrue(recordingTimer.exists)
        
        // Simulate recording for a few seconds
        sleep(3)
        
        // Stop recording
        stopRecordingButton.tap()
        
        // MARK: - Processing Screen Tests
        
        // Verify processing screen
        let processingAnimation = app.images["ProcessingAnimation"]
        let processingTitle = app.staticTexts["CookingYourStory"]
        
        XCTAssertTrue(processingAnimation.exists)
        XCTAssertTrue(processingTitle.exists)
        
        // Wait for processing to complete (mock should be fast)
        let resultsScreen = app.staticTexts["YourEnhancedStory"]
        let resultsExists = resultsScreen.waitForExistence(timeout: 10)
        XCTAssertTrue(resultsExists)
        
        // MARK: - Results Screen Tests
        
        // Verify results screen elements
        let enhancedTranscript = app.scrollViews["EnhancedTranscript"]
        let insightsCards = app.collectionViews["InsightsCards"]
        let playButton = app.buttons["PlayEnhancedStory"]
        let homeButton = app.buttons["ReturnHomeButton"]
        
        XCTAssertTrue(enhancedTranscript.exists)
        XCTAssertTrue(insightsCards.exists)
        XCTAssertTrue(playButton.exists)
        XCTAssertTrue(homeButton.exists)
        
        // Test swipeable insights
        if insightsCards.cells.count > 0 {
            insightsCards.swipeLeft()
            sleep(1)
        }
        
        // Test transcript expansion
        enhancedTranscript.tap()
        
        // Return to home
        homeButton.tap()
        
        // Verify back at home screen
        XCTAssertTrue(photoImageView.exists)
        XCTAssertTrue(recordButton.exists)
    }
    
    func testPermissionsFlow() throws {
        // Test permission request flow
        
        let recordButton = app.buttons["RecordStoryButton"]
        recordButton.tap()
        
        // Handle permission alerts if they appear
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        
        // Photo library permission
        let photoPermissionAlert = springboard.alerts.firstMatch
        if photoPermissionAlert.exists {
            photoPermissionAlert.buttons["Allow"].tap()
        }
        
        // Microphone permission
        let microphonePermissionAlert = springboard.alerts.firstMatch
        if microphonePermissionAlert.exists {
            microphonePermissionAlert.buttons["Allow"].tap()
        }
        
        // Speech recognition permission
        let speechPermissionAlert = springboard.alerts.firstMatch
        if speechPermissionAlert.exists {
            speechPermissionAlert.buttons["OK"].tap()
        }
    }
    
    func testRecordingCancellation() throws {
        // Test canceling a recording in progress
        
        let recordButton = app.buttons["RecordStoryButton"]
        recordButton.tap()
        
        // Wait for recording screen
        let cancelButton = app.buttons["CancelRecordingButton"]
        let cancelExists = cancelButton.waitForExistence(timeout: 5)
        XCTAssertTrue(cancelExists)
        
        // Cancel recording
        cancelButton.tap()
        
        // Should return to home screen
        let photoImageView = app.images["StoryPromptPhoto"]
        XCTAssertTrue(photoImageView.exists)
    }
    
    func testErrorHandling() throws {
        // Test error state handling
        
        // Force an error state (this would need to be simulated in the app)
        // For example, disable network and try to process
        
        let recordButton = app.buttons["RecordStoryButton"]
        recordButton.tap()
        
        let stopRecordingButton = app.buttons["StopRecordingButton"]
        let stopExists = stopRecordingButton.waitForExistence(timeout: 5)
        XCTAssertTrue(stopExists)
        
        stopRecordingButton.tap()
        
        // If an error occurs, should show error alert
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            XCTAssertTrue(errorAlert.staticTexts["Network Error"].exists ||
                         errorAlert.staticTexts["AI Processing Failed"].exists)
            errorAlert.buttons["OK"].tap()
        }
    }
    
    func testAccessibilityFeatures() throws {
        // Test VoiceOver and accessibility features
        
        let photoImageView = app.images["StoryPromptPhoto"]
        let recordButton = app.buttons["RecordStoryButton"]
        
        // Verify accessibility labels exist
        XCTAssertNotNil(photoImageView.label)
        XCTAssertNotNil(recordButton.label)
        
        // Test accessibility actions
        XCTAssertTrue(recordButton.isHittable)
        XCTAssertTrue(photoImageView.isHittable)
    }
    
    func testPerformanceMetrics() throws {
        // Test app launch and transition performance
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
        
        let recordButton = app.buttons["RecordStoryButton"]
        
        measure(metrics: [XCTClockMetric()]) {
            recordButton.tap()
            
            let stopButton = app.buttons["StopRecordingButton"]
            _ = stopButton.waitForExistence(timeout: 5)
        }
    }
}
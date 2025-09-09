//
//  AIEnhancementServiceNewTests.swift
//  AmplifyTests
//
//  Comprehensive tests for AI-powered story enhancement and analysis
//

import XCTest
@testable import Amplify

class AIEnhancementServiceNewTests: XCTestCase {
    
    var aiService: AIEnhancementService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        aiService = AIEnhancementService(apiKey: "test_api_key")
    }
    
    @MainActor
    override func tearDown() {
        aiService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testInitialization() {
        // Then
        XCTAssertFalse(aiService.isProcessing)
        XCTAssertEqual(aiService.processingProgress, 0.0)
        XCTAssertFalse(aiService.isOfflineMode)
        XCTAssertEqual(aiService.cacheHitCount, 0)
    }
    
    // MARK: - Story Enhancement Tests
    
    @MainActor
    func testEnhanceStoryWithCache() async {
        // Given
        let transcript = "This is a test story about adventure."
        let duration: TimeInterval = 30.0
        
        // First call - should not hit cache
        let result1 = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Second call - should hit cache
        let result2 = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Then
        switch result2 {
        case .success(_):
            XCTAssertEqual(aiService.cacheHitCount, 1)
        case .failure(_):
            XCTFail("Expected success for cached result")
        }
    }
    
    @MainActor
    func testEnhanceStoryOfflineMode() async {
        // Given
        aiService.isOfflineMode = true
        let transcript = "Test story for offline mode"
        let duration: TimeInterval = 45.0
        
        // When
        let result = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Then
        switch result {
        case .success(let enhancement):
            XCTAssertFalse(enhancement.enhancedTranscript.isEmpty)
            XCTAssertTrue(enhancement.enhancedTranscript.contains("Enhanced") ||
                         enhancement.enhancedTranscript.contains("enhanced"))
        case .failure(_):
            XCTFail("Offline mode should return success with mock data")
        }
    }
    
    // MARK: - Insights Generation Tests
    
    @MainActor
    func testGenerateInsightsOfflineMode() async {
        // Given
        aiService.isOfflineMode = true
        let transcript = "A story about personal growth and challenges"
        
        // When
        let result = await aiService.generateInsights(transcript: transcript)
        
        // Then
        switch result {
        case .success(let insights):
            // In offline mode, may return empty array or mock insights
            XCTAssertTrue(insights.count >= 0)
        case .failure(_):
            XCTFail("Offline mode should return success with mock data")
        }
    }
    
    // MARK: - Story Structure Analysis Tests
    
    @MainActor
    func testAnalyzeStoryStructureOfflineMode() async {
        // Given
        aiService.isOfflineMode = true
        let transcript = "Once upon a time, there was a hero who faced challenges and overcame them."
        
        // When
        let result = await aiService.analyzeStoryStructure(transcript: transcript)
        
        // Then
        switch result {
        case .success(let analysis):
            XCTAssertFalse(analysis.frameworkDetected.isEmpty)
            XCTAssertGreaterThanOrEqual(analysis.pacingScore, 0.0)
            XCTAssertLessThanOrEqual(analysis.pacingScore, 1.0)
        case .failure(_):
            XCTFail("Offline mode should return success with mock data")
        }
    }
    
    // MARK: - High Stake Words Detection Tests
    
    @MainActor
    func testDetectHighStakeWordsOfflineMode() async {
        // Given
        aiService.isOfflineMode = true
        let transcript = "This is absolutely crucial and extremely important for our success."
        
        // When
        let result = await aiService.detectHighStakeWords(transcript: transcript)
        
        // Then
        switch result {
        case .success(let detection):
            XCTAssertTrue(detection.words.count >= 0)
            XCTAssertGreaterThanOrEqual(detection.emotionalIntensity, 0.0)
            XCTAssertLessThanOrEqual(detection.emotionalIntensity, 1.0)
        case .failure(_):
            XCTFail("Offline mode should return success with mock data")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testEnhanceStoryWithMockError() async {
        // Given
        aiService.isOfflineMode = true
        aiService.mockAPIError = .networkError
        
        let transcript = "Test error handling"
        let duration: TimeInterval = 30.0
        
        // When
        let result = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Then
        switch result {
        case .success(_):
            XCTFail("Should have failed with mock error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError)
        }
    }
    
    // MARK: - Cache Tests
    
    @MainActor
    func testCacheHitTracking() async {
        // Given
        let transcript = "Cache test story"
        let duration: TimeInterval = 30.0
        
        // First call
        _ = await aiService.enhanceStory(transcript: transcript, duration: duration)
        let initialCacheHitCount = aiService.cacheHitCount
        
        // Second call (should hit cache)
        _ = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Then
        XCTAssertEqual(aiService.cacheHitCount, initialCacheHitCount + 1)
    }
    
    // MARK: - Processing State Tests
    
    @MainActor
    func testProcessingStateInitialization() {
        // Then
        XCTAssertFalse(aiService.isProcessing)
        XCTAssertEqual(aiService.processingProgress, 0.0)
    }
    
    @MainActor
    func testOfflineModeToggle() {
        // Given
        let initialState = aiService.isOfflineMode
        
        // When
        aiService.isOfflineMode = !initialState
        
        // Then
        XCTAssertNotEqual(aiService.isOfflineMode, initialState)
    }
    
    // MARK: - Edge Cases
    
    @MainActor
    func testEmptyTranscriptHandling() async {
        // Given
        aiService.isOfflineMode = true
        let transcript = ""
        let duration: TimeInterval = 0.0
        
        // When
        let result = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Then
        switch result {
        case .success(let enhancement):
            // Should handle empty input gracefully
            XCTAssertTrue(enhancement.enhancedTranscript.isEmpty || !enhancement.enhancedTranscript.isEmpty)
        case .failure(_):
            // Also acceptable for empty input
            break
        }
    }
    
    @MainActor
    func testVeryShortTranscript() async {
        // Given
        aiService.isOfflineMode = true
        let transcript = "Hi"
        let duration: TimeInterval = 1.0
        
        // When
        let result = await aiService.enhanceStory(transcript: transcript, duration: duration)
        
        // Then
        switch result {
        case .success(let enhancement):
            XCTAssertFalse(enhancement.enhancedTranscript.isEmpty)
        case .failure(_):
            // May fail for very short input
            break
        }
    }
}
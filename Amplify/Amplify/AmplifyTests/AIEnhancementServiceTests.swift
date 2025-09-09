//
//  AIEnhancementServiceTests.swift
//  AmplifyTests
//
//  Test-Driven Development for AI Enhancement Service
//

import XCTest
@testable import Amplify

class AIEnhancementServiceTests: XCTestCase {
    
    var aiService: AIEnhancementService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        aiService = AIEnhancementService()
    }
    
    @MainActor
    override func tearDown() {
        aiService = nil
        super.tearDown()
    }
    
    @MainActor
    func testEnhanceStoryTranscript() async throws {
        // Given
        let originalTranscript = "The sunset was nice. It was over the mountains."
        aiService.mockAPIResponse = """
        {
            "enhanced_transcript": "The breathtaking sunset painted the sky in vibrant hues of orange and gold as it gracefully descended behind the majestic mountain peaks.",
            "insights": [
                {
                    "title": "Vivid Imagery",
                    "category": "vocabulary",
                    "description": "Enhanced with more descriptive language",
                    "suggestion": "Continue using sensory details to paint pictures with words",
                    "confidence": 0.9
                }
            ],
            "word_highlights": [
                {
                    "word": "nice",
                    "timestamp": 2.5,
                    "suggested": "breathtaking"
                }
            ]
        }
        """
        
        // When
        let result = await aiService.enhanceStory(transcript: originalTranscript, duration: 15.0)
        
        // Then
        switch result {
        case .success(let enhancement):
            XCTAssertNotEqual(enhancement.enhancedTranscript, originalTranscript)
            XCTAssertTrue(enhancement.enhancedTranscript.contains("breathtaking"))
            XCTAssertTrue(enhancement.enhancedTranscript.contains("majestic"))
            XCTAssertEqual(enhancement.insights.count, 1)
            XCTAssertEqual(enhancement.insights[0].category, .vocabulary)
            XCTAssertEqual(enhancement.wordHighlights.count, 1)
            XCTAssertEqual(enhancement.wordHighlights[0].suggested, "breathtaking")
        case .failure:
            XCTFail("Story enhancement should succeed with mock data")
        }
    }
    
    @MainActor
    func testGenerateInsightsFromTranscript() async throws {
        // Given
        let transcript = "So yesterday I was walking through the park and I saw this amazing sunset. It was like, you know, really beautiful and made me think about life and stuff."
        aiService.mockAPIResponse = """
        {
            "insights": [
                {
                    "title": "STAR Method Opportunity",
                    "category": "framework",
                    "description": "Story could benefit from clearer structure",
                    "suggestion": "Try: Situation (park walk), Task (observing), Action (reflecting), Result (life insights)",
                    "confidence": 0.85
                },
                {
                    "title": "Eliminate Filler Words",
                    "category": "technique",
                    "description": "Multiple filler words detected",
                    "suggestion": "Replace 'like' and 'you know' with purposeful pauses",
                    "confidence": 0.92
                }
            ]
        }
        """
        
        // When
        let result = await aiService.generateInsights(transcript: transcript)
        
        // Then
        switch result {
        case .success(let insights):
            XCTAssertEqual(insights.count, 2)
            XCTAssertEqual(insights[0].category, .framework)
            XCTAssertEqual(insights[1].category, .technique)
            XCTAssertTrue(insights[0].isActionable)
            XCTAssertTrue(insights[1].isActionable)
        case .failure:
            XCTFail("Insight generation should succeed with mock data")
        }
    }
    
    @MainActor
    func testAnalyzeStoryStructure() async throws {
        // Given
        let transcript = "First, I entered the office. Then, I met with my manager. Finally, we reached an agreement that benefited everyone."
        aiService.mockAPIResponse = """
        {
            "structure_analysis": {
                "framework_detected": "chronological",
                "has_clear_beginning": true,
                "has_clear_middle": true,
                "has_clear_end": true,
                "emotional_arc": "stable_positive",
                "pacing_score": 0.75
            }
        }
        """
        
        // When
        let result = await aiService.analyzeStoryStructure(transcript: transcript)
        
        // Then
        switch result {
        case .success(let analysis):
            XCTAssertEqual(analysis.frameworkDetected, "chronological")
            XCTAssertTrue(analysis.hasClearBeginning)
            XCTAssertTrue(analysis.hasClearMiddle)
            XCTAssertTrue(analysis.hasClearEnd)
            XCTAssertEqual(analysis.emotionalArc, "stable_positive")
            XCTAssertEqual(analysis.pacingScore, 0.75, accuracy: 0.01)
        case .failure:
            XCTFail("Structure analysis should succeed with mock data")
        }
    }
    
    @MainActor
    func testDetectHighStakeWords() async throws {
        // Given
        let transcript = "The extraordinary sunset was absolutely magnificent and breathtaking beyond belief."
        aiService.mockAPIResponse = """
        {
            "high_stake_words": [
                "extraordinary",
                "absolutely",
                "magnificent",
                "breathtaking",
                "beyond belief"
            ],
            "emotional_intensity": 0.88
        }
        """
        
        // When
        let result = await aiService.detectHighStakeWords(transcript: transcript)
        
        // Then
        switch result {
        case .success(let detection):
            XCTAssertEqual(detection.words.count, 5)
            XCTAssertTrue(detection.words.contains("extraordinary"))
            XCTAssertTrue(detection.words.contains("magnificent"))
            XCTAssertEqual(detection.emotionalIntensity, 0.88, accuracy: 0.01)
        case .failure:
            XCTFail("High stake word detection should succeed with mock data")
        }
    }
    
    @MainActor
    func testAPIErrorHandling() async {
        // Given
        aiService.mockAPIError = .networkError
        
        // When
        let result = await aiService.enhanceStory(transcript: "test", duration: 10.0)
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with network error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError)
        }
    }
    
    @MainActor
    func testRateLimitHandling() async {
        // Given
        aiService.mockAPIError = .rateLimitExceeded
        
        // When
        let result = await aiService.enhanceStory(transcript: "test", duration: 10.0)
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with rate limit error")
        case .failure(let error):
            XCTAssertEqual(error, .rateLimitExceeded)
        }
    }
    
    @MainActor
    func testInvalidResponseHandling() async {
        // Given
        aiService.mockAPIResponse = "invalid json response"
        
        // When
        let result = await aiService.enhanceStory(transcript: "test", duration: 10.0)
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid response")
        case .failure(let error):
            XCTAssertEqual(error, .invalidResponse)
        }
    }
    
    @MainActor
    func testOfflineModeHandling() async {
        // Given
        aiService.isOfflineMode = true
        
        // When
        let result = await aiService.enhanceStory(transcript: "test story", duration: 10.0)
        
        // Then
        switch result {
        case .success(let enhancement):
            // Should return basic enhancement in offline mode
            XCTAssertEqual(enhancement.enhancedTranscript, "test story")
            XCTAssertTrue(enhancement.insights.isEmpty)
        case .failure:
            XCTFail("Offline mode should provide fallback")
        }
    }
    
    @MainActor
    func testRequestRetryMechanism() async {
        // Given
        aiService.mockRetryCount = 2
        aiService.mockAPIError = .networkError
        
        // When
        let result = await aiService.enhanceStory(transcript: "test", duration: 10.0)
        
        // Then
        XCTAssertEqual(aiService.actualRetryCount, 2)
        switch result {
        case .success:
            XCTFail("Should fail after retries")
        case .failure(let error):
            XCTAssertEqual(error, .networkError)
        }
    }
    
    @MainActor
    func testCachingMechanism() async throws {
        // Given
        let transcript = "test transcript for caching"
        aiService.mockAPIResponse = """
        {
            "enhanced_transcript": "enhanced test transcript",
            "insights": [],
            "word_highlights": []
        }
        """
        
        // When - First call
        let result1 = await aiService.enhanceStory(transcript: transcript, duration: 10.0)
        
        // Second call with same transcript
        aiService.mockAPIResponse = "should not be used due to caching"
        let result2 = await aiService.enhanceStory(transcript: transcript, duration: 10.0)
        
        // Then
        switch (result1, result2) {
        case (.success(let enhancement1), .success(let enhancement2)):
            XCTAssertEqual(enhancement1.enhancedTranscript, enhancement2.enhancedTranscript)
            XCTAssertEqual(aiService.cacheHitCount, 1)
        default:
            XCTFail("Both calls should succeed")
        }
    }
}
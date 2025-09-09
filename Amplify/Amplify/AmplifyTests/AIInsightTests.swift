//
//  AIInsightTests.swift
//  AmplifyTests
//
//  Test-Driven Development for AI Insight Model
//

import XCTest
@testable import Amplify

class AIInsightTests: XCTestCase {
    
    @MainActor
    func testAIInsightInitialization() {
        // Given
        let id = UUID()
        let title = "STAR Method Framework"
        let category = AIInsightCategory.framework
        let description = "Your story follows the STAR framework structure"
        let suggestion = "Continue using this effective structure"
        let confidence = 0.85
        
        // When
        let insight = AIInsight(
            id: id,
            title: title,
            category: category,
            description: description,
            suggestion: suggestion,
            confidence: confidence
        )
        
        // Then
        XCTAssertEqual(insight.id, id)
        XCTAssertEqual(insight.title, title)
        XCTAssertEqual(insight.category, category)
        XCTAssertEqual(insight.description, description)
        XCTAssertEqual(insight.suggestion, suggestion)
        XCTAssertEqual(insight.confidence, confidence, accuracy: 0.01)
    }
    
    @MainActor
    func testAIInsightCategoryTypes() {
        // Test all category types exist and are accessible
        let framework = AIInsightCategory.framework
        let vocabulary = AIInsightCategory.vocabulary
        let technique = AIInsightCategory.technique
        let pacing = AIInsightCategory.pacing
        let structure = AIInsightCategory.structure
        
        XCTAssertNotNil(framework)
        XCTAssertNotNil(vocabulary)
        XCTAssertNotNil(technique)
        XCTAssertNotNil(pacing)
        XCTAssertNotNil(structure)
    }
    
    @MainActor
    func testAIInsightWithHighStakeWords() {
        // Given
        let insight = AIInsight(
            id: UUID(),
            title: "High-Impact Words",
            category: .vocabulary,
            description: "Strong emotional language detected",
            suggestion: "Continue using powerful descriptive words"
        )
        let highStakeWords = ["breathtaking", "extraordinary", "magnificent"]
        
        // When
        insight.setHighStakeWords(highStakeWords)
        
        // Then
        XCTAssertEqual(insight.highStakeWords.count, 3)
        XCTAssertTrue(insight.highStakeWords.contains("breathtaking"))
    }
    
    @MainActor
    func testAIInsightIsActionable() {
        // Given
        let actionableInsight = AIInsight(
            id: UUID(),
            title: "Pacing Improvement",
            category: .pacing,
            description: "Consider varying your tempo",
            suggestion: "Add 2-second pauses before key points"
        )
        let nonActionableInsight = AIInsight(
            id: UUID(),
            title: "Good Structure",
            category: .structure,
            description: "Story has clear beginning, middle, end",
            suggestion: nil
        )
        
        // Then
        XCTAssertTrue(actionableInsight.isActionable)
        XCTAssertFalse(nonActionableInsight.isActionable)
    }
    
    @MainActor
    func testAIInsightEquality() {
        // Given
        let id = UUID()
        let insight1 = AIInsight(
            id: id,
            title: "Test",
            category: .framework,
            description: "Description",
            suggestion: "Suggestion"
        )
        let insight2 = AIInsight(
            id: id,
            title: "Different Title",
            category: .vocabulary,
            description: "Different Description",
            suggestion: "Different Suggestion"
        )
        let insight3 = AIInsight(
            id: UUID(),
            title: "Test",
            category: .framework,
            description: "Description",
            suggestion: "Suggestion"
        )
        
        // Then
        XCTAssertEqual(insight1, insight2) // Same ID
        XCTAssertNotEqual(insight1, insight3) // Different ID
    }
}
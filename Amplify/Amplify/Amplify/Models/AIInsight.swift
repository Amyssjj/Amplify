//
//  AIInsight.swift
//  Amplify
//
//  Core data model for AI-generated insights
//

import Foundation

@MainActor
class AIInsight: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var title: String
    let category: AIInsightCategory
    @Published var description: String
    @Published var suggestion: String?
    @Published var confidence: Double
    @Published var highStakeWords: [String] = []
    
    var isActionable: Bool {
        return suggestion != nil && !suggestion!.isEmpty
    }
    
    init(
        id: UUID,
        title: String,
        category: AIInsightCategory,
        description: String,
        suggestion: String? = nil,
        confidence: Double = 0.8
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.suggestion = suggestion
        self.confidence = confidence
    }
    
    func setHighStakeWords(_ words: [String]) {
        self.highStakeWords = words
    }
    
    nonisolated static func == (lhs: AIInsight, rhs: AIInsight) -> Bool {
        return lhs.id == rhs.id
    }
}

enum AIInsightCategory: String, CaseIterable, Codable {
    case framework = "framework"
    case vocabulary = "vocabulary"
    case technique = "technique"
    case pacing = "pacing"
    case structure = "structure"
    case engagement = "engagement"
    case clarity = "clarity"
    case emotion = "emotion"
    
    var displayName: String {
        switch self {
        case .framework:
            return "Story Framework"
        case .vocabulary:
            return "Word Choice"
        case .technique:
            return "Technique"
        case .pacing:
            return "Pacing & Rhythm"
        case .structure:
            return "Structure"
        case .engagement:
            return "Engagement"
        case .clarity:
            return "Clarity"
        case .emotion:
            return "Emotional Impact"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .framework:
            return "square.3.layers.3d"
        case .vocabulary:
            return "text.bubble"
        case .technique:
            return "wand.and.stars"
        case .pacing:
            return "metronome"
        case .structure:
            return "building.columns"
        case .engagement:
            return "heart.circle"
        case .clarity:
            return "eye"
        case .emotion:
            return "theatermasks"
        }
    }
}
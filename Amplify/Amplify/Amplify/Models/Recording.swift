//
//  Recording.swift
//  Amplify
//
//  Core data model for user recordings
//

import Foundation

@MainActor
class Recording: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var transcript: String
    @Published var enhancedTranscript: String?
    @Published var enhancementId: String?
    @Published var duration: Double
    let photoURL: String
    let timestamp: Date
    @Published var insights: [AIInsight] = []
    @Published var wordHighlights: [WordHighlight] = []
    
    var originalTranscript: String {
        return transcript
    }
    
    init(id: UUID, transcript: String, duration: Double, photoURL: String, timestamp: Date) {
        self.id = id
        self.transcript = transcript
        self.duration = duration
        self.photoURL = photoURL
        self.timestamp = timestamp
    }
    
    func setEnhancedTranscript(_ enhanced: String) {
        self.enhancedTranscript = enhanced
    }
    
    func setEnhancementId(_ id: String) {
        self.enhancementId = id
    }
    
    func addInsight(_ insight: AIInsight) {
        // Check for duplicate IDs before adding
        if insights.contains(where: { $0.id == insight.id }) {
            print("🔴 WARNING: Duplicate insight ID detected: \(insight.id) for '\(insight.title)'")
            print("🔴 Current insights count: \(insights.count)")
            print("🔴 Current insight titles: \(insights.map { $0.title })")
            return // Don't add duplicate
        }
        insights.append(insight)
        print("✅ Added insight: '\(insight.title)' (ID: \(insight.id)), total: \(insights.count)")
    }
    
    func setWordHighlights(_ highlights: [WordHighlight]) {
        self.wordHighlights = highlights
    }
    
    nonisolated static func == (lhs: Recording, rhs: Recording) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WordHighlight: Identifiable, Codable {
    let id: UUID
    let word: String
    let timestamp: Double
    let suggested: String?
    
    init(word: String, timestamp: Double, suggested: String? = nil) {
        self.id = UUID()
        self.word = word
        self.timestamp = timestamp
        self.suggested = suggested
    }
}
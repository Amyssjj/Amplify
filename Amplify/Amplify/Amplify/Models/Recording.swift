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
    
    func addInsight(_ insight: AIInsight) {
        insights.append(insight)
    }
    
    func setWordHighlights(_ highlights: [WordHighlight]) {
        self.wordHighlights = highlights
    }
    
    static func == (lhs: Recording, rhs: Recording) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WordHighlight: Identifiable, Codable {
    let id = UUID()
    let word: String
    let timestamp: Double
    let suggested: String?
    
    init(word: String, timestamp: Double, suggested: String? = nil) {
        self.word = word
        self.timestamp = timestamp
        self.suggested = suggested
    }
}
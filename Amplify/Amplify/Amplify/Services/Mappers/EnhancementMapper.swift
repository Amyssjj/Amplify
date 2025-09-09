//
//  EnhancementMapper.swift
//  AmplifyAPI
//
//  Maps between API models and app models for enhancement data
//

import Foundation

struct EnhancementMapper {

    // MARK: - Map API response to Recording

    static func mapToRecording(
        from response: EnhancementTextResponse,
        originalRecording: Recording
    ) async -> Recording {
        let callId = UUID().uuidString.prefix(8)
        print(
            "🔵 MAPPER CALL [\(callId)]: mapToRecording(EnhancementTextResponse) for recording \(originalRecording.id)"
        )

        return await MainActor.run {
            // Update the original recording with enhanced data
            originalRecording.setEnhancedTranscript(response.enhancedTranscript)
            originalRecording.setEnhancementId(response.enhancementId)

            // Map insights to AIInsight objects
            let insights = mapInsightsToAIInsights(from: response.insights)

            // Clear existing insights and add new ones
            print(
                "🔵 Recording had \(originalRecording.insights.count) insights, clearing and adding \(insights.count) new insights"
            )
            originalRecording.insights.removeAll()
            for insight in insights {
                print("🔵 Adding insight: '\(insight.title)' (ID: \(insight.id))")
                originalRecording.addInsight(insight)
            }
            print("🔵 Recording now has \(originalRecording.insights.count) total insights")

            return originalRecording
        }
    }

    static func mapToRecording(
        from details: EnhancementDetails,
        originalRecording: Recording
    ) async -> Recording {
        let callId = UUID().uuidString.prefix(8)
        print(
            "🔵 MAPPER CALL [\(callId)]: mapToRecording(EnhancementDetails) for recording \(originalRecording.id)"
        )

        return await MainActor.run {
            // Update recording with detailed enhancement data
            originalRecording.setEnhancedTranscript(details.enhancedTranscript)

            // Map insights
            let insights = mapInsightsToAIInsights(from: details.insights)
            print(
                "🔵 (Details) Recording had \(originalRecording.insights.count) insights, clearing and adding \(insights.count) new insights"
            )
            originalRecording.insights.removeAll()
            for insight in insights {
                print("🔵 (Details) Adding insight: '\(insight.title)' (ID: \(insight.id))")
                originalRecording.addInsight(insight)
            }
            print(
                "🔵 (Details) Recording now has \(originalRecording.insights.count) total insights")

            return originalRecording
        }
    }

    // MARK: - Map Recording to API request

    @MainActor
    static func mapToEnhancementRequest(
        from recording: Recording,
        photoData: Data
    ) -> EnhancementRequest {
        // Convert photo data to Base64 string as required by API
        let photoBase64String = photoData.base64EncodedString()

        return EnhancementRequest(
            photoBase64: photoBase64String,
            transcript: recording.originalTranscript,
            language: "en"  // Default to English, could be configurable
        )
    }

    // MARK: - Private Helper Methods

    @MainActor
    private static func mapInsightsToAIInsights(from apiInsights: [String: String]) -> [AIInsight] {
        print("🔵 Processing \(apiInsights.count) dynamic insights from API")
        return apiInsights.map { (key, value) in
            // Use dynamic category assignment based on content analysis
            let category = determineCategoryFromContent(title: key, description: value)
            let insightId = UUID()

            print("🔵 Creating insight '\(key)' with ID: \(insightId)")

            return AIInsight(
                id: insightId,
                title: key,  // Use the API-provided title directly
                category: category,
                description: value,
                suggestion: extractSuggestionFromDescription(value),
                confidence: 0.8  // Default confidence, API doesn't provide this
            )
        }
    }

    private static func determineCategoryFromContent(title: String, description: String)
        -> AIInsightCategory
    {
        let combinedText = "\(title) \(description)".lowercased()

        // Analyze content to determine the most appropriate category
        let emotionKeywords = [
            "feeling", "emotion", "vivid", "charm", "picture", "scene", "atmosphere", "mood",
        ]
        let engagementKeywords = [
            "conversation", "reply", "response", "connect", "audience", "listener", "engaging",
            "chat", "two-way",
        ]
        let techniqueKeywords = [
            "technique", "method", "approach", "way", "style", "manner", "conversational", "flow",
        ]
        let clarityKeywords = [
            "clear", "understand", "explain", "detail", "specific", "precise", "clarity",
        ]
        let vocabularyKeywords = [
            "word", "language", "phrase", "expression", "vocabulary", "wording",
        ]
        let structureKeywords = [
            "structure", "organization", "format", "beginning", "middle", "end", "framework",
        ]
        let pacingKeywords = ["pace", "timing", "rhythm", "speed", "flow", "progression"]

        // Count matches for each category
        var scores: [AIInsightCategory: Int] = [:]

        scores[.emotion] = emotionKeywords.filter { combinedText.contains($0) }.count
        scores[.engagement] = engagementKeywords.filter { combinedText.contains($0) }.count
        scores[.technique] = techniqueKeywords.filter { combinedText.contains($0) }.count
        scores[.clarity] = clarityKeywords.filter { combinedText.contains($0) }.count
        scores[.vocabulary] = vocabularyKeywords.filter { combinedText.contains($0) }.count
        scores[.structure] = structureKeywords.filter { combinedText.contains($0) }.count
        scores[.pacing] = pacingKeywords.filter { combinedText.contains($0) }.count

        // Return the category with the highest score, or default to technique
        return scores.max(by: { $0.value < $1.value })?.key ?? AIInsightCategory.technique
    }

    private static func extractSuggestionFromDescription(_ description: String) -> String? {
        // The API description often contains actionable advice
        // Look for sentences that provide guidance or suggestions
        let sentences = description.components(separatedBy: ". ")

        // Find sentences with suggestion indicators
        let suggestionIndicators = [
            "try", "consider", "use", "add", "start with", "instead of", "helps", "makes", "can",
        ]

        for sentence in sentences {
            let lowerSentence = sentence.lowercased()
            if suggestionIndicators.contains(where: { lowerSentence.contains($0) }) {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // If no explicit suggestion found, return nil (insight is informational)
        return nil
    }
}

// MARK: - Historical Enhancement Mapping

extension EnhancementMapper {

    /// Create a minimal Recording from EnhancementSummary for history display
    @MainActor
    static func mapToRecording(from summary: EnhancementSummary) -> Recording {
        let recording = Recording(
            id: UUID(),  // Generate new UUID for UI
            transcript: summary.transcriptPreview,
            duration: 0.0,  // Duration not available from API
            photoURL: "",  // Photo not available in summary
            timestamp: summary.createdAt
        )

        return recording
    }

    /// Map GetEnhancements200Response to array of Recordings
    @MainActor
    static func mapToRecordings(from response: GetEnhancements200Response) -> [Recording] {
        return response.items.map { summary in
            mapToRecording(from: summary)
        }
    }
}

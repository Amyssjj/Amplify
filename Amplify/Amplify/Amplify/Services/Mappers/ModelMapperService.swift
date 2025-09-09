//
//  ModelMapperService.swift
//  AmplifyAPI
//
//  Centralized service for all model mapping operations
//

import Foundation

@MainActor
class ModelMapperService: ObservableObject {
    
    // MARK: - Enhancement Mapping
    
    /// Map API enhancement response to update existing Recording
    func mapEnhancementResponse(
        _ response: EnhancementTextResponse,
        to recording: Recording
    ) async -> Recording {
        return await EnhancementMapper.mapToRecording(
            from: response,
            originalRecording: recording
        )
    }
    
    /// Map API enhancement details to update existing Recording
    func mapEnhancementDetails(
        _ details: EnhancementDetails,
        to recording: Recording
    ) async -> Recording {
        return await EnhancementMapper.mapToRecording(
            from: details,
            originalRecording: recording
        )
    }
    
    /// Create enhancement request from Recording
    func createEnhancementRequest(
        from recording: Recording,
        with photoData: Data
    ) -> EnhancementRequest {
        return EnhancementMapper.mapToEnhancementRequest(
            from: recording,
            photoData: photoData
        )
    }
    
    /// Map historical enhancements to Recordings for display
    func mapHistoricalEnhancements(
        _ response: GetEnhancements200Response
    ) -> [Recording] {
        return EnhancementMapper.mapToRecordings(from: response)
    }
    
    // MARK: - User Mapping
    
    /// Map authentication response to User
    func mapAuthenticationResponse(_ response: AuthResponse) -> User {
        return UserMapper.mapToUser(from: response)
    }
    
    // MARK: - Audio Enhancement Mapping
    
    /// Handle audio response data
    func processAudioResponse(_ response: EnhancementAudioResponse) -> Data {
        return response.audioBase64
    }
    
    // MARK: - Validation Helpers
    
    /// Validate that an API response contains required data
    func validateEnhancementResponse(_ response: EnhancementTextResponse) -> Bool {
        return !response.enhancementId.isEmpty &&
               !response.enhancedTranscript.isEmpty
    }
    
    /// Validate enhancement details response
    func validateEnhancementDetails(_ details: EnhancementDetails) -> Bool {
        return !details.enhancementId.isEmpty &&
               !details.enhancedTranscript.isEmpty &&
               !details.originalTranscript.isEmpty
    }
    
    /// Check if insights contain meaningful data
    func hasValidInsights(_ insights: [String: String]) -> Bool {
        return !insights.isEmpty && insights.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

// MARK: - Error Handling

extension ModelMapperService {
    
    enum MappingError: Error, LocalizedError {
        case invalidEnhancementResponse(String)
        case invalidUserData(String)
        case missingRequiredField(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidEnhancementResponse(let message):
                return "Invalid enhancement response: \(message)"
            case .invalidUserData(let message):
                return "Invalid user data: \(message)"
            case .missingRequiredField(let field):
                return "Missing required field: \(field)"
            }
        }
    }
    
    /// Safely map enhancement response with error handling
    func safelyMapEnhancement(
        _ response: EnhancementTextResponse?,
        to recording: Recording
    ) async throws -> Recording {
        guard let response = response else {
            throw MappingError.invalidEnhancementResponse("Response is nil")
        }
        
        guard validateEnhancementResponse(response) else {
            throw MappingError.invalidEnhancementResponse("Response missing required fields")
        }
        
        return await mapEnhancementResponse(response, to: recording)
    }
}

// MARK: - Logging and Debug Support

extension ModelMapperService {
    
    /// Log mapping operation for debugging
    private func logMappingOperation(_ operation: String, details: String = "") {
        #if DEBUG
        print("🔄 ModelMapper: \(operation) \(details)")
        #endif
    }
    
    /// Debug method to print insight mapping
    func debugInsightMapping(_ insights: [String: String]) {
        #if DEBUG
        print("🔍 Mapping insights:")
        for (key, value) in insights {
            print("  \(key): \(value)")
        }
        #endif
    }
}
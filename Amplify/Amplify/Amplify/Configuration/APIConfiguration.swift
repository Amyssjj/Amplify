//
//  APIConfiguration.swift
//  Amplify
//
//  API configuration for different environments
//

import Foundation

struct APIConfiguration {
    
    // MARK: - Environment Configuration
    
    static var baseURL: URL {
        #if DEBUG
        return URL(string: "https://amplify-backend.replit.app")!
        #else
        return URL(string: "https://amplify-backend.replit.app")!
        #endif
    }
    
    static var environment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    // MARK: - API Endpoints
    
    enum Endpoints {
        static let authentication = "/api/v1/auth/google"
        static let enhancements = "/api/v1/enhancements"
        static let health = "/api/v1/health"
        
        static func enhancementDetails(id: String) -> String {
            return "/api/v1/enhancements/\(id)"
        }
        
        static func enhancementAudio(id: String) -> String {
            return "/api/v1/enhancements/\(id)/audio"
        }
    }
    
    // MARK: - Network Configuration
    
    enum NetworkConfig {
        static let defaultTimeout: TimeInterval = 30.0
        static let authTimeout: TimeInterval = 15.0
        static let uploadTimeout: TimeInterval = 60.0
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 2.0
    }
    
    // MARK: - Feature Flags
    
    enum FeatureFlags {
        static let enableAudioGeneration = true
        static let enableOfflineMode = false
        static let enableAnalytics = false
        static let enableDebugLogging = true
        
        #if DEBUG
        static let mockAPIResponses = false // Set to true for testing without backend
        #else
        static let mockAPIResponses = false
        #endif
    }
    
    // MARK: - Supporting Types
    
    enum Environment {
        case development
        case production
        
        var description: String {
            switch self {
            case .development:
                return "Development"
            case .production:
                return "Production"
            }
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension APIConfiguration {
    static func printConfiguration() {
        print("🔧 API Configuration")
        print("Environment: \(environment.description)")
        print("Base URL: \(baseURL.absoluteString)")
        print("Timeout: \(NetworkConfig.defaultTimeout)s")
        print("Max Retries: \(NetworkConfig.maxRetries)")
        print("Mock Responses: \(FeatureFlags.mockAPIResponses)")
        print("Audio Generation: \(FeatureFlags.enableAudioGeneration)")
        print("Debug Logging: \(FeatureFlags.enableDebugLogging)")
        print("────────────────────────────────")
    }
}
#endif
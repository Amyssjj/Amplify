//
//  EnhancementService.swift
//  AmplifyAPI
//
//  High-level service coordinating API operations, authentication, and model mapping
//

import Foundation
import UIKit

// MARK: - Enhancement Service Protocol

@MainActor
protocol EnhancementServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    
    func signInWithGoogle(idToken: String) async throws -> User
    func signOut() async
    
    func enhanceRecording(_ recording: Recording, photoData: Data) async throws -> Recording
    func getEnhancementAudio(for recording: Recording, enhancementId: String) async throws -> Data
    func getEnhancementHistory(limit: Int, offset: Int) async throws -> [Recording]
    func getEnhancementDetails(enhancementId: String) async throws -> EnhancementDetails
}

// MARK: - Enhancement Service Implementation

@MainActor
class EnhancementService: ObservableObject, EnhancementServiceProtocol {
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    // MARK: - Dependencies
    private let apiClient: APIClientProtocol
    private let authService: AuthenticationServiceProtocol
    private let mapperService: ModelMapperService
    private let networkManager: NetworkManagerProtocol
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        return authService.currentToken != nil && authService.isTokenValid()
    }
    
    var currentUser: User? {
        return authService.currentUser
    }
    
    var isNetworkAvailable: Bool {
        return networkManager.isConnected
    }
    
    // MARK: - Initialization
    
    init(
        apiClient: APIClientProtocol? = nil,
        authService: AuthenticationServiceProtocol? = nil,
        mapperService: ModelMapperService? = nil,
        networkManager: NetworkManagerProtocol? = nil
    ) {
        // Use dependency injection or create defaults
        let baseURL = URL(string: "https://amplify-backend.replit.app")!
        let networkMgr = networkManager ?? NetworkManager()
        
        self.networkManager = networkMgr
        self.mapperService = mapperService ?? ModelMapperService()
        
        // Resolve circular dependency properly
        if let providedAuthService = authService, let providedAPIClient = apiClient {
            // Both provided - use as-is
            self.authService = providedAuthService
            self.apiClient = providedAPIClient
        } else {
            // Create with proper dependency injection
            let authSvc = AuthenticationService()
            let apiClient = APIClient(baseURL: baseURL, authService: authSvc)
            
            // Inject the APIClient back into AuthenticationService
            authSvc.setAPIClient(apiClient)
            
            self.authService = authSvc
            self.apiClient = apiClient
        }
    }
    
    // MARK: - Authentication Methods
    
    func signInWithGoogle(idToken: String) async throws -> User {
        isProcessing = true
        lastError = nil
        
        do {
            let authResponse = try await authService.signInWithGoogle(idToken: idToken)
            let user = mapperService.mapAuthenticationResponse(authResponse)
            isProcessing = false
            return user
        } catch {
            lastError = error
            isProcessing = false
            throw error
        }
    }
    
    func signOut() async {
        isProcessing = true
        await authService.signOut()
        isProcessing = false
    }
    
    // MARK: - Enhancement Methods
    
    func enhanceRecording(_ recording: Recording, photoData: Data) async throws -> Recording {
        guard isAuthenticated else {
            throw EnhancementError.notAuthenticated
        }
        
        guard isNetworkAvailable else {
            throw EnhancementError.networkUnavailable
        }
        
        isProcessing = true
        lastError = nil
        
        do {
            // Test server connectivity first
            print("🔵 Testing server health...")
            do {
                _ = try await apiClient.getHealth()
                print("✅ Server health check passed")
            } catch {
                print("🟡 Server health check had issues (continuing anyway): \(error)")
                // Continue anyway - the health endpoint might have format issues but the main API might work
            }
            
            // Create enhancement request from recording
            let request = mapperService.createEnhancementRequest(
                from: recording,
                with: photoData
            )
            
            print("🔵 Enhancement request created:")
            print("  - Transcript length: \(request.transcript.count) characters")
            print("  - Photo Base64 length: \(request.photoBase64.count) characters")
            print("  - Language: \(request.language ?? "nil")")
            
            // Check payload size (Base64 is ~4/3 of original size, so 76KB Base64 ≈ 57KB original)
            let estimatedSizeMB = Double(request.photoBase64.count) / (1024 * 1024 * 4/3)
            print("  - Estimated image size: \(String(format: "%.2f", estimatedSizeMB)) MB")
            
            if estimatedSizeMB > 5.0 {
                print("🟡 Large payload detected, server may timeout")
            }
            
            // Call API to enhance the recording with retry for service unavailable
            print("🔵 Calling enhancement API...")
            let response = try await retryEnhancementRequest(request)
            print("✅ Enhancement API succeeded: \(response.enhancementId)")
            
            // Validate response
            guard mapperService.validateEnhancementResponse(response) else {
                throw EnhancementError.invalidResponse("Enhancement response is invalid")
            }
            
            // Map response back to recording
            let enhancedRecording = await mapperService.mapEnhancementResponse(
                response,
                to: recording
            )
            
            isProcessing = false
            return enhancedRecording
            
        } catch {
            lastError = error
            isProcessing = false
            throw error
        }
    }
    
    func getEnhancementAudio(for recording: Recording, enhancementId: String) async throws -> Data {
        guard isAuthenticated else {
            throw EnhancementError.notAuthenticated
        }
        
        guard isNetworkAvailable else {
            throw EnhancementError.networkUnavailable
        }
        
        isProcessing = true
        lastError = nil
        
        do {
            let audioResponse = try await apiClient.getEnhancementAudio(id: enhancementId)
            let audioData = mapperService.processAudioResponse(audioResponse)
            
            isProcessing = false
            return audioData
            
        } catch {
            lastError = error
            isProcessing = false
            throw error
        }
    }
    
    func getEnhancementHistory(limit: Int = 20, offset: Int = 0) async throws -> [Recording] {
        guard isAuthenticated else {
            throw EnhancementError.notAuthenticated
        }
        
        guard isNetworkAvailable else {
            throw EnhancementError.networkUnavailable
        }
        
        isProcessing = true
        lastError = nil
        
        do {
            let historyResponse = try await apiClient.getEnhancementHistory(
                limit: limit,
                offset: offset
            )
            
            let recordings = mapperService.mapHistoricalEnhancements(historyResponse)
            
            isProcessing = false
            return recordings
            
        } catch {
            lastError = error
            isProcessing = false
            throw error
        }
    }
    
    func getEnhancementDetails(enhancementId: String) async throws -> EnhancementDetails {
        guard isAuthenticated else {
            throw EnhancementError.notAuthenticated
        }
        
        guard isNetworkAvailable else {
            throw EnhancementError.networkUnavailable
        }
        
        isProcessing = true
        lastError = nil
        
        do {
            let details = try await apiClient.getEnhancementDetails(id: enhancementId)
            
            guard mapperService.validateEnhancementDetails(details) else {
                throw EnhancementError.invalidResponse("Enhancement details are invalid")
            }
            
            isProcessing = false
            return details
            
        } catch {
            lastError = error
            isProcessing = false
            throw error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func retryEnhancementRequest(_ request: EnhancementRequest, maxRetries: Int = 3) async throws -> EnhancementTextResponse {
        for attempt in 1...maxRetries {
            do {
                return try await apiClient.createEnhancement(request)
            } catch let apiError as APIError {
                if case .serviceUnavailable(let message) = apiError {
                    if attempt < maxRetries {
                        let delay = Double(attempt) * 5.0 // 5, 10, 15 second delays
                        print("🟡 AI service unavailable (attempt \(attempt)/\(maxRetries)). Retrying in \(delay) seconds...")
                        print("🟡 Message: \(message)")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                // If not service unavailable or max retries reached, throw the error
                throw apiError
            }
        }
        // This should never be reached, but satisfies the compiler
        throw EnhancementError.processingFailed("Maximum retries exceeded")
    }
    
    // MARK: - Utility Methods
    
    func refreshAuthenticationIfNeeded() async -> Bool {
        return await authService.refreshTokenIfNeeded()
    }
    
    func checkNetworkStatus() -> Bool {
        return networkManager.isConnected
    }
    
    /// Helper method to convert UIImage to Data for API requests
    func imageToData(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
}

// MARK: - Error Types

enum EnhancementError: Error, LocalizedError, Equatable {
    case notAuthenticated
    case networkUnavailable
    case invalidResponse(String)
    case processingFailed(String)
    case audioNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be signed in to enhance recordings"
        case .networkUnavailable:
            return "Network connection is required"
        case .invalidResponse(let message):
            return "Invalid API response: \(message)"
        case .processingFailed(let message):
            return "Enhancement processing failed: \(message)"
        case .audioNotAvailable:
            return "Audio is not yet available for this enhancement"
        }
    }
    
    static func == (lhs: EnhancementError, rhs: EnhancementError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.networkUnavailable, .networkUnavailable),
             (.audioNotAvailable, .audioNotAvailable):
            return true
        case (.invalidResponse(let lhsMessage), .invalidResponse(let rhsMessage)),
             (.processingFailed(let lhsMessage), .processingFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Enhancement Service Factory

extension EnhancementService {
    
    /// Create service with production configuration
    static func production() -> EnhancementService {
        let baseURL = URL(string: "https://amplify-backend.replit.app")!
        let networkManager = NetworkManager()
        let authService = AuthenticationService()
        let apiClient = APIClient(baseURL: baseURL, authService: authService)
        let mapperService = ModelMapperService()
        
        // Resolve circular dependency
        authService.setAPIClient(apiClient)
        
        return EnhancementService(
            apiClient: apiClient,
            authService: authService,
            mapperService: mapperService,
            networkManager: networkManager
        )
    }
    
    /// Create service with development configuration
    static func development() -> EnhancementService {
        let baseURL = URL(string: "https://amplify-backend.replit.app")!
        let networkManager = NetworkManager()
        let authService = AuthenticationService()
        let apiClient = APIClient(baseURL: baseURL, authService: authService)
        let mapperService = ModelMapperService()
        
        // Resolve circular dependency
        authService.setAPIClient(apiClient)
        
        return EnhancementService(
            apiClient: apiClient,
            authService: authService,
            mapperService: mapperService,
            networkManager: networkManager
        )
    }
}

// MARK: - Enhancement Service State

extension EnhancementService {
    
    enum ServiceState {
        case idle
        case authenticating
        case processing
        case error(Error)
        
        var isProcessing: Bool {
            switch self {
            case .authenticating, .processing:
                return true
            default:
                return false
            }
        }
    }
}
//
//  APIClient.swift
//  AmplifyAPI
//
//  HTTP client with JWT authentication for Amplify API
//

import Foundation

// MARK: - URLSession Protocol

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - API Client Protocol

protocol APIClientProtocol {
    // Authentication
    func authenticate(googleToken: String) async throws -> AuthResponse
    
    // Enhancement Flow
    func createEnhancement(_ request: EnhancementRequest) async throws -> EnhancementTextResponse
    func getEnhancementAudio(id: String) async throws -> EnhancementAudioResponse
    
    // History
    func getEnhancementHistory(limit: Int, offset: Int) async throws -> GetEnhancements200Response
    func getEnhancementDetails(id: String) async throws -> EnhancementDetails
    
    // Health
    func getHealth() async throws -> GetHealth200Response
}

// MARK: - API Client Implementation

@MainActor
class APIClient: ObservableObject, APIClientProtocol {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastError: APIError?
    
    // MARK: - Private Properties
    private let session: URLSessionProtocol
    private let authService: AuthenticationServiceProtocol
    private let baseURL: URL
    
    // Configuration
    private let requestTimeout: TimeInterval = 60.0  // Increased timeout for large payloads
    private let maxRetries = 3
    
    // MARK: - Initialization
    
    init(
        baseURL: URL = URL(string: "https://amplify-backend.replit.app")!,
        authService: AuthenticationServiceProtocol,
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.authService = authService
        self.session = session
    }
    
    // MARK: - Authentication
    
    func authenticate(googleToken: String) async throws -> AuthResponse {
        let request = GoogleAuthRequest(idToken: googleToken)
        
        return try await performRequest(
            endpoint: "/api/v1/auth/google",
            method: .POST,
            body: request,
            responseType: AuthResponse.self,
            requiresAuth: false
        )
    }
    
    // MARK: - Enhancement API
    
    func createEnhancement(_ request: EnhancementRequest) async throws -> EnhancementTextResponse {
        return try await performRequest(
            endpoint: "/api/v1/enhancements",
            method: .POST,
            body: request,
            responseType: EnhancementTextResponse.self
        )
    }
    
    func getEnhancementAudio(id: String) async throws -> EnhancementAudioResponse {
        return try await performRequest(
            endpoint: "/api/v1/enhancements/\(id)/audio",
            method: .GET,
            responseType: EnhancementAudioResponse.self
        )
    }
    
    func getEnhancementHistory(limit: Int = 20, offset: Int = 0) async throws -> GetEnhancements200Response {
        let queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        return try await performRequest(
            endpoint: "/api/v1/enhancements",
            method: .GET,
            queryItems: queryItems,
            responseType: GetEnhancements200Response.self
        )
    }
    
    func getEnhancementDetails(id: String) async throws -> EnhancementDetails {
        return try await performRequest(
            endpoint: "/api/v1/enhancements/\(id)",
            method: .GET,
            responseType: EnhancementDetails.self
        )
    }
    
    // MARK: - Health API
    
    func getHealth() async throws -> GetHealth200Response {
        return try await performRequest(
            endpoint: "/health",
            method: .GET,
            responseType: GetHealth200Response.self,
            requiresAuth: false
        )
    }
    
    // MARK: - Private Implementation
    
    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: (any Codable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        responseType: T.Type,
        requiresAuth: Bool = true
    ) async throws -> T {
        
        isLoading = true
        defer { isLoading = false }
        
        // Build URL
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw APIError.invalidURL(endpoint)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout
        
        // Add authentication if required
        if requiresAuth {
            print("🔵 Authentication required for API call")
            print("🔵 AuthService type: \(type(of: authService))")
            
            var authToken: String?
            
            if let token = authService.currentToken {
                print("🔵 Got token from authService.currentToken")
                authToken = token
            } else {
                print("🔴 No token from authService.currentToken - trying refresh")
                // Try to refresh token first
                let refreshed = await authService.refreshTokenIfNeeded()
                print("🔵 Token refresh result: \(refreshed)")
                if refreshed {
                    authToken = authService.currentToken
                    print("🔵 Got token after refresh: \(authToken != nil)")
                } else {
                    print("🔴 Token refresh failed")
                }
            }
            
            guard let token = authToken else {
                print("🔴 No valid authentication token available")
                throw APIError.unauthorized("Authentication required - please sign in again")
            }
            
            print("🔵 Adding Bearer token to Authorization header")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }
        
        // Log the request for debugging
        print("🔵 Making \(method.rawValue) request to: \(url)")
        print("🔵 Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            print("🔵 Body size: \(body.count) bytes")
        }
        
        // Perform request with retry logic
        return try await performRequestWithRetry(request: request, responseType: responseType)
    }
    
    private func performRequestWithRetry<T: Codable>(
        request: URLRequest,
        responseType: T.Type,
        attemptNumber: Int = 1
    ) async throws -> T {
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse("Not an HTTP response")
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    return try JSONDecoder().decode(responseType, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
                
            case 400:
                // Bad request - try to decode validation error
                if let validationError = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data) {
                    throw APIError.validationError(validationError)
                } else if let errorResponse = try? JSONDecoder().decode(ModelErrorResponse.self, from: data) {
                    throw APIError.badRequest(errorResponse.message)
                } else {
                    throw APIError.badRequest("Bad request")
                }
                
            case 401:
                // Unauthorized - try to refresh token and retry
                if attemptNumber == 1 {
                    let refreshSuccess = await authService.refreshTokenIfNeeded()
                    if refreshSuccess {
                        // Token refreshed, retry request
                        var newRequest = request
                        if let token = authService.currentToken {
                            newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        }
                        return try await performRequestWithRetry(request: newRequest, responseType: responseType, attemptNumber: 2)
                    }
                }
                
                // Token refresh failed or max attempts reached
                let errorMessage = try? JSONDecoder().decode(ModelErrorResponse.self, from: data)
                throw APIError.unauthorized(errorMessage?.message ?? "Unauthorized")
                
            case 404:
                let errorMessage = try? JSONDecoder().decode(ModelErrorResponse.self, from: data)
                throw APIError.notFound(errorMessage?.message ?? "Not found")
                
            case 429:
                // Rate limited - implement exponential backoff
                if attemptNumber < maxRetries {
                    let delay = Double(attemptNumber) * 2.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await performRequestWithRetry(request: request, responseType: responseType, attemptNumber: attemptNumber + 1)
                } else {
                    throw APIError.rateLimited("Too many requests")
                }
                
            case 500...599:
                print("🔴 Server error \(httpResponse.statusCode)")
                print("🔴 Response headers: \(httpResponse.allHeaderFields)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("🔴 Response body: \(responseData)")
                }
                let errorMessage = try? JSONDecoder().decode(ModelErrorResponse.self, from: data)
                
                // Handle specific service unavailable errors
                if httpResponse.statusCode == 503 {
                    if let responseBody = String(data: data, encoding: .utf8),
                       responseBody.contains("AI service temporarily unavailable") {
                        throw APIError.serviceUnavailable("The AI enhancement service is temporarily unavailable. Please try again in a few moments.")
                    }
                    throw APIError.serviceUnavailable("Service temporarily unavailable (HTTP 503)")
                }
                
                throw APIError.serverError(errorMessage?.message ?? "Server error (HTTP \(httpResponse.statusCode))")
                
            default:
                throw APIError.unexpectedStatusCode(httpResponse.statusCode)
            }
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            // Network or other system error
            print("🔴 Network error (attempt \(attemptNumber)/\(maxRetries)): \(error)")
            print("🔴 Error type: \(type(of: error))")
            if let urlError = error as? URLError {
                print("🔴 URLError code: \(urlError.code.rawValue) - \(urlError.localizedDescription)")
            }
            
            if attemptNumber < maxRetries {
                let delay = Double(attemptNumber) * 1.0
                print("🔵 Retrying in \(delay) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequestWithRetry(request: request, responseType: responseType, attemptNumber: attemptNumber + 1)
            } else {
                let apiError = APIError.networkError(error)
                lastError = apiError
                throw apiError
            }
        }
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - API Error Types

enum APIError: Error, LocalizedError, Equatable {
    case invalidURL(String)
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case invalidResponse(String)
    case unauthorized(String)
    case badRequest(String)
    case validationError(ValidationErrorResponse)
    case notFound(String)
    case rateLimited(String)
    case serverError(String)
    case serviceUnavailable(String)
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .validationError(let validationError):
            return "Validation error: \(validationError.message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .rateLimited(let message):
            return "Rate limited: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .serviceUnavailable(let message):
            return "\(message)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        }
    }
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case let (.invalidURL(l), .invalidURL(r)): return l == r
        case let (.unauthorized(l), .unauthorized(r)): return l == r
        case let (.badRequest(l), .badRequest(r)): return l == r
        case let (.notFound(l), .notFound(r)): return l == r
        case let (.rateLimited(l), .rateLimited(r)): return l == r
        case let (.serverError(l), .serverError(r)): return l == r
        case let (.serviceUnavailable(l), .serviceUnavailable(r)): return l == r
        case let (.unexpectedStatusCode(l), .unexpectedStatusCode(r)): return l == r
        default: return false
        }
    }
}
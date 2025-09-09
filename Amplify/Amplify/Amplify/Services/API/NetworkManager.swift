//
//  NetworkManager.swift
//  AmplifyAPI
//
//  Low-level HTTP operations and request/response handling
//

import Foundation
import Network

// MARK: - Network Manager Protocol

protocol NetworkManagerProtocol {
    func performRequest<T: Codable>(
        _ request: NetworkRequest<T>
    ) async throws -> T
    
    var isConnected: Bool { get }
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - Network Request Model

struct NetworkRequest<ResponseType: Codable> {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let timeout: TimeInterval
    let responseType: ResponseType.Type
}

// MARK: - Network Manager Implementation

class NetworkManager: ObservableObject, NetworkManagerProtocol {
    
    // MARK: - Published Properties
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType = .wifi
    
    // MARK: - Private Properties
    private let session: URLSession
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    // Configuration
    private let defaultTimeout: TimeInterval = 30.0
    private let maxRetries = 3
    
    // MARK: - Initialization
    
    init(session: URLSession = .shared) {
        self.session = session
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if let interface = path.availableInterfaces.first {
                    self?.connectionType = interface.type
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Request Execution
    
    func performRequest<T: Codable>(
        _ request: NetworkRequest<T>
    ) async throws -> T {
        
        // Check network connectivity
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        // Create URL request
        let urlRequest = createURLRequest(from: request)
        
        // Execute with retry logic
        return try await executeWithRetry(urlRequest, responseType: request.responseType)
    }
    
    // MARK: - Private Methods
    
    private func createURLRequest<T: Codable>(from request: NetworkRequest<T>) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout
        
        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body
        urlRequest.httpBody = request.body
        
        return urlRequest
    }
    
    private func executeWithRetry<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type,
        attempt: Int = 1
    ) async throws -> T {
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse("Response is not HTTP")
            }
            
            // Log request/response for debugging
            logRequest(request, response: httpResponse, data: data)
            
            // Validate status code
            try validateStatusCode(httpResponse.statusCode, data: data)
            
            // Decode response
            return try decodeResponse(data, responseType: responseType)
            
        } catch let error as NetworkError {
            throw error
        } catch {
            // Handle network errors with retry logic
            if attempt < maxRetries && shouldRetry(error: error) {
                let delay = calculateRetryDelay(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request, responseType: responseType, attempt: attempt + 1)
            } else {
                throw NetworkError.requestFailed(error)
            }
        }
    }
    
    private func validateStatusCode(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return // Success
        case 400:
            throw NetworkError.badRequest(extractErrorMessage(from: data))
        case 401:
            throw NetworkError.unauthorized(extractErrorMessage(from: data))
        case 403:
            throw NetworkError.forbidden(extractErrorMessage(from: data))
        case 404:
            throw NetworkError.notFound(extractErrorMessage(from: data))
        case 429:
            throw NetworkError.rateLimited(extractErrorMessage(from: data))
        case 500...599:
            throw NetworkError.serverError(statusCode, extractErrorMessage(from: data))
        default:
            throw NetworkError.unexpectedStatusCode(statusCode)
        }
    }
    
    private func decodeResponse<T: Codable>(_ data: Data, responseType: T.Type) throws -> T {
        let decoder = JSONDecoder()
        
        // Configure decoder for API responses
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            // Log decoding error with response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Decoding error for response: \(responseString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String {
        // Try to extract error message from API error response
        if let errorResponse = try? JSONDecoder().decode(ModelErrorResponse.self, from: data) {
            return errorResponse.message
        } else if let validationError = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data) {
            return validationError.message
        } else {
            return "Unknown error"
        }
    }
    
    private func shouldRetry(error: Error) -> Bool {
        // Retry on network errors, but not on client/server errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func calculateRetryDelay(attempt: Int) -> Double {
        // Exponential backoff with jitter
        let baseDelay = Double(attempt) * 2.0
        let jitter = Double.random(in: 0...1)
        return baseDelay + jitter
    }
    
    private func logRequest(_ request: URLRequest, response: HTTPURLResponse, data: Data) {
        #if DEBUG
        print("🌐 HTTP \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")")
        print("📤 Status: \(response.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8), responseString.count < 1000 {
            print("📥 Response: \(responseString)")
        } else {
            print("📥 Response: \(data.count) bytes")
        }
        #endif
    }
}

// MARK: - Network Error Types

enum NetworkError: Error, LocalizedError, Equatable {
    case noConnection
    case invalidResponse(String)
    case badRequest(String)
    case unauthorized(String)
    case forbidden(String)
    case notFound(String)
    case rateLimited(String)
    case serverError(Int, String)
    case unexpectedStatusCode(Int)
    case requestFailed(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .forbidden(let message):
            return "Forbidden: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .rateLimited(let message):
            return "Rate limited: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection): return true
        case let (.invalidResponse(l), .invalidResponse(r)): return l == r
        case let (.badRequest(l), .badRequest(r)): return l == r
        case let (.unauthorized(l), .unauthorized(r)): return l == r
        case let (.forbidden(l), .forbidden(r)): return l == r
        case let (.notFound(l), .notFound(r)): return l == r
        case let (.rateLimited(l), .rateLimited(r)): return l == r
        case let (.serverError(lCode, lMsg), .serverError(rCode, rMsg)): return lCode == rCode && lMsg == rMsg
        case let (.unexpectedStatusCode(l), .unexpectedStatusCode(r)): return l == r
        default: return false
        }
    }
}

// MARK: - Network Request Builder

struct NetworkRequestBuilder<ResponseType: Codable> {
    private var url: URL?
    private var method: HTTPMethod = .GET
    private var headers: [String: String] = [:]
    private var body: Data?
    private var timeout: TimeInterval = 30.0
    private let responseType: ResponseType.Type
    
    init(responseType: ResponseType.Type) {
        self.responseType = responseType
    }
    
    func url(_ url: URL) -> Self {
        var builder = self
        builder.url = url
        return builder
    }
    
    func method(_ method: HTTPMethod) -> Self {
        var builder = self
        builder.method = method
        return builder
    }
    
    func header(_ key: String, value: String) -> Self {
        var builder = self
        builder.headers[key] = value
        return builder
    }
    
    func headers(_ headers: [String: String]) -> Self {
        var builder = self
        builder.headers.merge(headers) { _, new in new }
        return builder
    }
    
    func body<T: Codable>(_ object: T) throws -> Self {
        var builder = self
        builder.body = try JSONEncoder().encode(object)
        builder.headers["Content-Type"] = "application/json"
        return builder
    }
    
    func timeout(_ timeout: TimeInterval) -> Self {
        var builder = self
        builder.timeout = timeout
        return builder
    }
    
    func build() throws -> NetworkRequest<ResponseType> {
        guard let url = url else {
            throw NetworkError.invalidResponse("URL is required")
        }
        
        return NetworkRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            timeout: timeout,
            responseType: responseType
        )
    }
}
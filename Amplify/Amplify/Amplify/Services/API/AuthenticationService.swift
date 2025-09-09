//
//  AuthenticationService.swift
//  AmplifyAPI
//
//  Google OAuth integration and JWT token management
//

import Foundation

// MARK: - Authentication Service Protocol

@MainActor
protocol AuthenticationServiceProtocol {
    var authenticationState: AuthenticationState { get }
    var currentUser: User? { get }
    var currentToken: String? { get }

    func signInWithGoogle(idToken: String) async throws -> AuthResponse
    func refreshTokenIfNeeded() async -> Bool
    func signOut() async
    func isTokenValid() -> Bool
}

// MARK: - Authentication State

enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
}

// MARK: - User Model

struct User: Codable, Equatable {
    let id: String
    let email: String
    let name: String?
    let profileImageURL: String?

    init(id: String, email: String, name: String? = nil, profileImageURL: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
    }

    init(from authUser: AuthResponseUser) {
        self.id = authUser.userId
        self.email = authUser.email
        self.name = authUser.name
        self.profileImageURL = authUser.picture
    }

    // MARK: - Computed Properties

    var displayName: String {
        return name ?? email.components(separatedBy: "@").first ?? "User"
    }

    var initials: String {
        let components = (name ?? email).components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(components[0].prefix(2)).uppercased()
        }
    }

    var hasProfileImage: Bool {
        return profileImageURL != nil && !profileImageURL!.isEmpty
    }
}

// MARK: - Authentication Service Implementation

@MainActor
class AuthenticationService: ObservableObject, AuthenticationServiceProtocol {

    // MARK: - Published Properties
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var currentUser: User?

    // MARK: - Private Properties
    private let tokenStorage: TokenStorage
    private var _currentToken: String?
    private var tokenExpirationDate: Date?

    // Dependencies
    private var apiClient: APIClientProtocol?

    // MARK: - Computed Properties

    var currentToken: String? {
        let isValid = isTokenValid()
        print(
            "🔵 currentToken requested - isValid: \(isValid), hasToken: \(_currentToken != nil)")
        if let expiration = tokenExpirationDate {
            print("🔵 Token expiration: \(expiration), now: \(Date())")
        }
        guard isValid else {
            print("🔴 Token invalid - returning nil")
            return nil
        }
        print("🔵 Returning valid token")
        return _currentToken
    }

    // MARK: - Initialization

    init(
        tokenStorage: TokenStorage = KeychainTokenStorage(), apiClient: APIClientProtocol? = nil
    ) {
        self.tokenStorage = tokenStorage
        self.apiClient = apiClient

        // Load existing authentication state
        Task {
            await loadStoredAuthentication()
        }
    }

    // MARK: - Public Methods

    func setAPIClient(_ client: APIClientProtocol) {
        self.apiClient = client
    }

    func signInWithGoogle(idToken: String) async throws -> AuthResponse {
        authenticationState = .authenticating

        do {

            // For initial implementation, we'll need to handle the circular dependency
            // This will be resolved when we inject the API client properly
            guard let apiClient = apiClient else {
                throw AuthenticationError.noAPIClient
            }

            let authResponse = try await apiClient.authenticate(googleToken: idToken)

            // Store tokens and user info
            try await storeAuthenticationData(authResponse)

            // Update state
            let user = User(from: authResponse.user)
            currentUser = user
            authenticationState = .authenticated(user)

            return authResponse

        } catch {
            let errorMessage = error.localizedDescription
            authenticationState = .error(errorMessage)
            throw error
        }
    }

    func refreshTokenIfNeeded() async -> Bool {
        // Check if token needs refresh (within 5 minutes of expiry)
        guard let expiration = tokenExpirationDate else { return false }

        let refreshThreshold = Date().addingTimeInterval(5 * 60)  // 5 minutes from now

        if expiration < refreshThreshold {
            return await refreshToken()
        }

        return true  // Token is still valid
    }

    func signOut() async {
        // Clear stored tokens
        await tokenStorage.clearTokens()

        // Reset state
        _currentToken = nil
        tokenExpirationDate = nil
        currentUser = nil
        authenticationState = .unauthenticated
    }

    func isTokenValid() -> Bool {
        guard _currentToken != nil,
            let expiration = tokenExpirationDate
        else {
            return false
        }

        return Date() < expiration
    }

    // MARK: - Private Methods

    private func loadStoredAuthentication() async {
        if let storedToken = await tokenStorage.getAccessToken(),
            let storedUser = await tokenStorage.getUser(),
            let expiration = await tokenStorage.getTokenExpiration()
        {

            _currentToken = storedToken
            tokenExpirationDate = expiration
            currentUser = storedUser

            if isTokenValid() {
                authenticationState = .authenticated(storedUser)
                print("✅ Restored valid authentication state")
            } else {
                // Token expired - need to clear auth state completely
                print("🔴 Stored token expired - signing out user")
                _currentToken = nil
                tokenExpirationDate = nil
                currentUser = nil
                authenticationState = .unauthenticated

                // Clear from storage too
                await tokenStorage.clearTokens()
            }
        }
    }

    private func storeAuthenticationData(_ authResponse: AuthResponse) async throws {
        let user = User(from: authResponse.user)

        // Use the actual expiration time from backend for now
        // TODO: Implement proper refresh token flow for longer sessions
        let expiresIn = authResponse.expiresIn ?? 3600  // Backend default (1 hour)
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))

        print("🔵 Token expires in \(expiresIn) seconds (~\(expiresIn/3600) hours)")

        // Update local state first
        _currentToken = authResponse.accessToken
        tokenExpirationDate = expirationDate
        currentUser = user

        // Try to store in keychain, but don't fail auth if storage fails
        do {
            try await tokenStorage.storeTokens(
                accessToken: authResponse.accessToken,
                expiration: expirationDate,
                user: user
            )
            print("✅ Successfully stored authentication data")
        } catch {
            print("⚠️ Failed to store authentication data: \(error.localizedDescription)")
            // Authentication still succeeds even if storage fails
        }
    }

    private func refreshToken() async -> Bool {
        // JWT tokens from Google don't support refresh without user interaction
        // Clear expired token and require re-authentication

        print("🔴 Token refresh failed - user needs to re-authenticate")

        // Clear the expired token and reset authentication state
        _currentToken = nil
        tokenExpirationDate = nil
        currentUser = nil
        authenticationState = .unauthenticated

        // Clear from storage as well
        await tokenStorage.clearTokens()

        // Return false to indicate refresh failed
        return false
    }
}

// MARK: - Authentication Errors

enum AuthenticationError: Error, LocalizedError, Equatable {
    case noAPIClient
    case invalidGoogleToken
    case tokenExpired
    case refreshFailed
    case storageError(Error)

    var errorDescription: String? {
        switch self {
        case .noAPIClient:
            return "API client not available for authentication"
        case .invalidGoogleToken:
            return "Invalid Google ID token"
        case .tokenExpired:
            return "Authentication token has expired"
        case .refreshFailed:
            return "Failed to refresh authentication token"
        case .storageError(let error):
            return "Token storage error: \(error.localizedDescription)"
        }
    }

    static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.noAPIClient, .noAPIClient),
            (.invalidGoogleToken, .invalidGoogleToken),
            (.tokenExpired, .tokenExpired),
            (.refreshFailed, .refreshFailed):
            return true
        case (.storageError(let lhsError), .storageError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Token Storage Protocol

protocol TokenStorage {
    func storeTokens(accessToken: String, expiration: Date, user: User) async throws
    func getAccessToken() async -> String?
    func getTokenExpiration() async -> Date?
    func getUser() async -> User?
    func clearTokens() async
}

// MARK: - Keychain Token Storage

class KeychainTokenStorage: TokenStorage {

    private let service = "com.amplify.api.tokens"
    private let accessTokenKey = "access_token"
    private let expirationKey = "token_expiration"
    private let userKey = "user_data"

    func storeTokens(accessToken: String, expiration: Date, user: User) async throws {
        // Store access token
        try storeString(accessToken, forKey: accessTokenKey)

        // Store expiration date
        let expirationData = try JSONEncoder().encode(expiration)
        try storeData(expirationData, forKey: expirationKey)

        // Store user data
        let userData = try JSONEncoder().encode(user)
        try storeData(userData, forKey: userKey)
    }

    func getAccessToken() async -> String? {
        return getString(forKey: accessTokenKey)
    }

    func getTokenExpiration() async -> Date? {
        guard let data = getData(forKey: expirationKey) else { return nil }
        return try? JSONDecoder().decode(Date.self, from: data)
    }

    func getUser() async -> User? {
        guard let data = getData(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func clearTokens() async {
        deleteItem(forKey: accessTokenKey)
        deleteItem(forKey: expirationKey)
        deleteItem(forKey: userKey)
    }

    // MARK: - Keychain Helpers

    private func storeString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw AuthenticationError.storageError(
                NSError(
                    domain: "KeychainStorage", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to encode string"]))
        }
        try storeData(data, forKey: key)
    }

    private func storeData(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthenticationError.storageError(
                NSError(
                    domain: "KeychainStorage", code: Int(status),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to store item in keychain"]))
        }
    }

    private func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func deleteItem(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }
}

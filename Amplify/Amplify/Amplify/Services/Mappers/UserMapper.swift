//
//  UserMapper.swift
//  AmplifyAPI
//
//  Maps between authentication API models and app user models
//

import Foundation

struct UserMapper {

    // MARK: - Map API User to App User

    static func mapToUser(from authResponse: AuthResponse) -> User {
        return User(from: authResponse.user)
    }

    static func mapToUser(from authUser: AuthResponseUser) -> User {
        return User(from: authUser)
    }

    // MARK: - User Profile Updates

    static func updateUserFromProfile(_ user: User, with profileData: [String: Any]) -> User {
        // In future, this could handle profile updates from API
        // For now, User is already mapped correctly from AuthResponseUser
        return user
    }
}

// MARK: - User Extension for Additional Functionality

extension User {

    /// Initialize User from AuthResponseUser (already exists in AuthenticationService)
    /// This extension provides additional convenience methods if needed in the future

    // Computed properties now defined in the User struct itself in AuthenticationService.swift
}

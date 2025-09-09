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

// MARK: - User Extension for Initialization

extension User {
    
    /// Initialize User from AuthResponseUser (already exists in AuthenticationService)
    /// This extension provides additional convenience methods
    
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
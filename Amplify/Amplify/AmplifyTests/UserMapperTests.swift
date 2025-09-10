//
//  UserMapperTests.swift
//  AmplifyTests
//
//  Tests for UserMapper functionality
//

import XCTest

@testable import Amplify

final class UserMapperTests: XCTestCase {

    // MARK: - AuthResponse to User Mapping Tests

    func testMapAuthResponseToUser() {
        // Given
        let authUser = AuthResponseUser(
            userId: "user123",
            email: "test@example.com",
            name: "Test User",
            picture: "https://example.com/avatar.jpg"
        )
        let authResponse = AuthResponse(
            accessToken: "jwt-token-123",
            user: authUser
        )

        // When
        let user = UserMapper.mapToUser(from: authResponse)

        // Then
        XCTAssertEqual(user.id, "user123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.profileImageURL, "https://example.com/avatar.jpg")
    }

    func testMapAuthResponseUserToUser() {
        // Given
        let authUser = AuthResponseUser(
            userId: "user456",
            email: "another@test.com",
            name: "Another User",
            picture: "https://example.com/photo.png"
        )

        // When
        let user = UserMapper.mapToUser(from: authUser)

        // Then
        XCTAssertEqual(user.id, "user456")
        XCTAssertEqual(user.email, "another@test.com")
        XCTAssertEqual(user.name, "Another User")
        XCTAssertEqual(user.profileImageURL, "https://example.com/photo.png")
    }

    // MARK: - Null/Empty Value Handling Tests

    func testMapAuthUserWithNullValues() {
        // Given
        let authUser = AuthResponseUser(
            userId: "user789",
            email: "nulltest@example.com",
            name: nil,
            picture: nil
        )

        // When
        let user = UserMapper.mapToUser(from: authUser)

        // Then
        XCTAssertEqual(user.id, "user789")
        XCTAssertEqual(user.email, "nulltest@example.com")
        XCTAssertNil(user.name)
        XCTAssertNil(user.profileImageURL)
    }

    func testMapAuthUserWithEmptyValues() {
        // Given
        let authUser = AuthResponseUser(
            userId: "user000",
            email: "empty@example.com",
            name: "",
            picture: ""
        )

        // When
        let user = UserMapper.mapToUser(from: authUser)

        // Then
        XCTAssertEqual(user.id, "user000")
        XCTAssertEqual(user.email, "empty@example.com")
        XCTAssertEqual(user.name, "")
        XCTAssertEqual(user.profileImageURL, "")
    }

    // MARK: - User Profile Update Tests

    func testUpdateUserFromProfile() {
        // Given
        let originalUser = User(
            id: "user123",
            email: "original@example.com",
            name: "Original Name",
            profileImageURL: "https://example.com/old.jpg"
        )
        let profileData: [String: Any] = [
            "name": "Updated Name",
            "picture": "https://example.com/new.jpg",
            "email": "updated@example.com",
        ]

        // When
        let updatedUser = UserMapper.updateUserFromProfile(originalUser, with: profileData)

        // Then
        // Currently UserMapper returns the original user unchanged
        // This test validates current behavior and could be updated if mapping logic changes
        XCTAssertEqual(updatedUser.id, originalUser.id)
        XCTAssertEqual(updatedUser.email, originalUser.email)
        XCTAssertEqual(updatedUser.name, originalUser.name)
        XCTAssertEqual(updatedUser.profileImageURL, originalUser.profileImageURL)
    }

    // MARK: - User Computed Properties Tests

    func testUserDisplayName() {
        // Test with name provided
        let userWithName = User(
            id: "user1",
            email: "test@example.com",
            name: "Test User"
        )
        XCTAssertEqual(userWithName.displayName, "Test User")

        // Test without name (should use email prefix)
        let userWithoutName = User(
            id: "user2",
            email: "johndoe@example.com",
            name: nil
        )
        XCTAssertEqual(userWithoutName.displayName, "johndoe")

        // Test with empty name (should use email prefix)
        let userWithEmptyName = User(
            id: "user3",
            email: "jane@example.com",
            name: ""
        )
        XCTAssertEqual(userWithEmptyName.displayName, "jane")
    }

    func testUserInitials() {
        // Test with full name (two words)
        let userFullName = User(
            id: "user1",
            email: "test@example.com",
            name: "John Doe"
        )
        XCTAssertEqual(userFullName.initials, "JD")

        // Test with single name
        let userSingleName = User(
            id: "user2",
            email: "test@example.com",
            name: "John"
        )
        XCTAssertEqual(userSingleName.initials, "JO")

        // Test with no name (should use email)
        let userNoName = User(
            id: "user3",
            email: "jane@example.com",
            name: nil
        )
        XCTAssertEqual(userNoName.initials, "JA")

        // Test with three words (should use first two)
        let userThreeWords = User(
            id: "user4",
            email: "test@example.com",
            name: "John Michael Doe"
        )
        XCTAssertEqual(userThreeWords.initials, "JM")
    }

    func testUserHasProfileImage() {
        // Test with profile image URL
        let userWithImage = User(
            id: "user1",
            email: "test@example.com",
            profileImageURL: "https://example.com/avatar.jpg"
        )
        XCTAssertTrue(userWithImage.hasProfileImage)

        // Test with nil profile image URL
        let userWithoutImage = User(
            id: "user2",
            email: "test@example.com",
            profileImageURL: nil
        )
        XCTAssertFalse(userWithoutImage.hasProfileImage)

        // Test with empty profile image URL
        let userWithEmptyImage = User(
            id: "user3",
            email: "test@example.com",
            profileImageURL: ""
        )
        XCTAssertFalse(userWithEmptyImage.hasProfileImage)
    }

    // MARK: - User Equality Tests

    func testUserEquality() {
        let user1 = User(
            id: "user123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: "https://example.com/avatar.jpg"
        )

        let user2 = User(
            id: "user123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: "https://example.com/avatar.jpg"
        )

        let user3 = User(
            id: "user456",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: "https://example.com/avatar.jpg"
        )

        XCTAssertEqual(user1, user2)  // Same data
        XCTAssertNotEqual(user1, user3)  // Different ID
    }

    // MARK: - User Codable Tests

    func testUserCodable() throws {
        // Given
        let originalUser = User(
            id: "user123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: "https://example.com/avatar.jpg"
        )

        // When - Encode
        let encodedData = try JSONEncoder().encode(originalUser)
        XCTAssertFalse(encodedData.isEmpty)

        // When - Decode
        let decodedUser = try JSONDecoder().decode(User.self, from: encodedData)

        // Then
        XCTAssertEqual(originalUser, decodedUser)
        XCTAssertEqual(originalUser.id, decodedUser.id)
        XCTAssertEqual(originalUser.email, decodedUser.email)
        XCTAssertEqual(originalUser.name, decodedUser.name)
        XCTAssertEqual(originalUser.profileImageURL, decodedUser.profileImageURL)
    }

    func testUserCodableWithNilValues() throws {
        // Given
        let originalUser = User(
            id: "user456",
            email: "test@example.com",
            name: nil,
            profileImageURL: nil
        )

        // When - Encode
        let encodedData = try JSONEncoder().encode(originalUser)

        // When - Decode
        let decodedUser = try JSONDecoder().decode(User.self, from: encodedData)

        // Then
        XCTAssertEqual(originalUser, decodedUser)
        XCTAssertNil(decodedUser.name)
        XCTAssertNil(decodedUser.profileImageURL)
    }
}

// MARK: - Test Helper Extensions

extension UserMapperTests {

    fileprivate func createMockAuthResponseUser(
        id: String = "test-user-123",
        email: String = "test@example.com",
        name: String? = "Test User",
        picture: String? = "https://example.com/avatar.jpg"
    ) -> AuthResponseUser {
        return AuthResponseUser(
            userId: id,
            email: email,
            name: name,
            picture: picture
        )
    }

    fileprivate func createMockAuthResponse(
        token: String = "mock-jwt-token",
        user: AuthResponseUser? = nil
    ) -> AuthResponse {
        let authUser = user ?? createMockAuthResponseUser()
        return AuthResponse(accessToken: token, user: authUser)
    }
}

//
//  PhotoLibraryServiceTests.swift
//  AmplifyTests
//
//  Test-Driven Development for Photo Library Service
//

import XCTest
import Photos
@testable import Amplify

class PhotoLibraryServiceTests: XCTestCase {
    
    var photoService: PhotoLibraryService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        photoService = PhotoLibraryService()
    }
    
    @MainActor
    override func tearDown() {
        photoService = nil
        super.tearDown()
    }
    
    @MainActor
    func testRequestPhotoLibraryPermission() async {
        // Given/When
        let permissionStatus = await photoService.requestPhotoLibraryPermission()
        
        // Then
        XCTAssertNotNil(permissionStatus)
        XCTAssertTrue([
            PhotoLibraryPermissionStatus.authorized,
            PhotoLibraryPermissionStatus.limited,
            PhotoLibraryPermissionStatus.denied,
            PhotoLibraryPermissionStatus.notDetermined
        ].contains(permissionStatus))
    }
    
    @MainActor
    func testFetchFavoritesAlbumWhenAuthorized() async throws {
        // Given
        photoService.mockPermissionStatus = .authorized
        
        // When
        let result = await photoService.fetchFavoritesAlbum()
        
        // Then
        switch result {
        case .success(let album):
            XCTAssertNotNil(album)
        case .failure(let error):
            // In test environment, this might fail due to no photos
            XCTAssertTrue(error is PhotoLibraryError)
        }
    }
    
    @MainActor
    func testFetchFavoritesAlbumWhenDenied() async {
        // Given
        photoService.mockPermissionStatus = .denied
        
        // When
        let result = await photoService.fetchFavoritesAlbum()
        
        // Then
        switch result {
        case .success:
            XCTFail("Should not succeed when permission denied")
        case .failure(let error):
            XCTAssertEqual(error as? PhotoLibraryError, .permissionDenied)
        }
    }
    
    @MainActor
    func testGetRandomPhotoFromFavorites() async {
        // Given
        photoService.mockPermissionStatus = .authorized
        let mockPhotos = createMockPhotoAssets(count: 5)
        photoService.mockFavoritePhotos = mockPhotos
        
        // When
        let result = await photoService.getRandomPhotoFromFavorites()
        
        // Then
        switch result {
        case .success(let photoData):
            XCTAssertNotNil(photoData.image)
            XCTAssertNotNil(photoData.identifier)
            XCTAssertTrue(mockPhotos.map(\.localIdentifier).contains(photoData.identifier))
        case .failure:
            XCTFail("Should succeed with mock data")
        }
    }
    
    @MainActor
    func testFallbackToRecentPhotosWhenFavoritesEmpty() async {
        // Given
        photoService.mockPermissionStatus = .authorized
        photoService.mockFavoritePhotos = [] // Empty favorites
        let mockRecentPhotos = createMockPhotoAssets(count: 3)
        photoService.mockRecentPhotos = mockRecentPhotos
        
        // When
        let result = await photoService.getRandomPhotoFromFavorites()
        
        // Then
        switch result {
        case .success(let photoData):
            XCTAssertNotNil(photoData.image)
            XCTAssertTrue(mockRecentPhotos.map(\.localIdentifier).contains(photoData.identifier))
        case .failure:
            XCTFail("Should fallback to recent photos")
        }
    }
    
    @MainActor
    func testGetFallbackPhoto() {
        // When
        let fallbackPhoto = photoService.getFallbackPhoto()
        
        // Then
        XCTAssertNotNil(fallbackPhoto.image)
        XCTAssertEqual(fallbackPhoto.identifier, "fallback-photo")
        XCTAssertFalse(fallbackPhoto.isFromUserLibrary)
    }
    
    @MainActor
    func testPhotoLibraryPermissionStatusMapping() {
        // Test mapping from PHAuthorizationStatus to our custom enum
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.authorized),
            .authorized
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.limited),
            .limited
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.denied),
            .denied
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.notDetermined),
            .notDetermined
        )
    }
    
    // MARK: - Helper Methods
    
    private func createMockPhotoAssets(count: Int) -> [MockPHAsset] {
        return (0..<count).map { index in
            MockPHAsset(localIdentifier: "mock-photo-\(index)")
        }
    }
}

// MARK: - Mock Classes for Testing

class MockPHAsset: PHAsset {
    private let mockIdentifier: String
    
    init(localIdentifier: String) {
        self.mockIdentifier = localIdentifier
        super.init()
    }
    
    override var localIdentifier: String {
        return mockIdentifier
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
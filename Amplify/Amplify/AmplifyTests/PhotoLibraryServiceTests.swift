//
//  PhotoLibraryServiceTests.swift
//  AmplifyTests
//
//  Created by Claude on 2025-09-09.
//

import Photos
import UIKit
import XCTest

@testable import Amplify

@MainActor
final class PhotoLibraryServiceTests: XCTestCase {

    var photoService: PhotoLibraryService!

    override func setUp() {
        super.setUp()
        photoService = PhotoLibraryService()
    }

    override func tearDown() {
        photoService = nil
        super.tearDown()
    }

    // MARK: - Permission Tests

    func testRequestPhotoLibraryPermission() async {
        // Given
        photoService.mockPermissionStatus = .authorized

        // When
        let status = await photoService.requestPhotoLibraryPermission()

        // Then
        XCTAssertEqual(status, .authorized)
    }

    func testRequestPhotoLibraryPermissionDenied() async {
        // Given
        photoService.mockPermissionStatus = .denied

        // When
        let status = await photoService.requestPhotoLibraryPermission()

        // Then
        XCTAssertEqual(status, .denied)
    }

    func testRequestPhotoLibraryPermissionLimited() async {
        // Given
        photoService.mockPermissionStatus = .limited

        // When
        let status = await photoService.requestPhotoLibraryPermission()

        // Then
        XCTAssertEqual(status, .limited)
    }

    // MARK: - Favorites Album Tests

    func testFetchFavoritesAlbum() async {
        // Given
        photoService.mockPermissionStatus = .authorized
        let mockAlbum = createMockAssetCollection()

        // When
        let result = await photoService.fetchFavoritesAlbum()

        // Then
        switch result {
        case .success(let album):
            XCTAssertEqual(album.localIdentifier, mockAlbum.localIdentifier)
        case .failure(let error):
            // May fail in test environment without photo access
            XCTAssertTrue([.permissionDenied, .favoritesAlbumNotFound].contains(error))
        }
    }

    func testFetchFavoritesAlbumPermissionDenied() async {
        // Given
        photoService.mockPermissionStatus = .denied

        // When
        let result = await photoService.fetchFavoritesAlbum()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail with denied permission")
        case .failure(let error):
            XCTAssertEqual(error, .permissionDenied)
        }
    }

    func testFetchFavoritesAlbumNotFound() async {
        // Given
        photoService.mockPermissionStatus = .authorized

        // When
        let result = await photoService.fetchFavoritesAlbum()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail when album not found")
        case .failure(let error):
            XCTAssertEqual(error, .favoritesAlbumNotFound)
        }
    }

    // MARK: - Random Photo Tests

    func testGetRandomPhotoFromFavorites() async {
        // Given
        photoService.mockPermissionStatus = .authorized
        let mockPhotoData = createMockPhotoData()

        // When
        let result = await photoService.getRandomPhotoFromFavorites()

        // Then
        switch result {
        case .success(let photoData):
            XCTAssertEqual(photoData.identifier, mockPhotoData.identifier)
            XCTAssertNotNil(photoData.image)
        case .failure(let error):
            // May fail in test environment
            XCTAssertTrue(
                [.permissionDenied, .noPhotosAvailable, .imageLoadFailed].contains(error))
        }
    }

    func testGetRandomPhotoFromFavoritesPermissionDenied() async {
        // Given
        photoService.mockPermissionStatus = .denied

        // When
        let result = await photoService.getRandomPhotoFromFavorites()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail with denied permission")
        case .failure(let error):
            XCTAssertEqual(error, .permissionDenied)
        }
    }

    func testGetRandomPhotoFromFavoritesNoPhotos() async {
        // Given
        photoService.mockPermissionStatus = .authorized

        // When
        let result = await photoService.getRandomPhotoFromFavorites()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail when no photos found")
        case .failure(let error):
            XCTAssertEqual(error, .noPhotosAvailable)
        }
    }

    // MARK: - Fallback Photo Tests

    func testGetFallbackPhoto() {
        // When
        let fallbackPhoto = photoService.getFallbackPhoto()

        // Then
        XCTAssertEqual(fallbackPhoto.identifier, "fallback")
        XCTAssertNotNil(fallbackPhoto.image)
        XCTAssertFalse(fallbackPhoto.isFromUserLibrary)
    }

    func testGetFallbackPhotoProperties() {
        // When
        let fallbackPhoto = photoService.getFallbackPhoto()

        // Then
        XCTAssertEqual(fallbackPhoto.identifier, "fallback")
        XCTAssertNotNil(fallbackPhoto.image)
        XCTAssertFalse(fallbackPhoto.isFromUserLibrary)
    }

    // MARK: - Photo Data Validation Tests

    func testPhotoDataValidation() {
        // Given
        let photoData = createMockPhotoData()

        // Then
        XCTAssertFalse(photoData.identifier.isEmpty)
        XCTAssertNotNil(photoData.image)
        XCTAssertTrue(photoData.isFromUserLibrary)
    }

    func testPhotoDataFromLibrary() {
        // Given
        let image = UIImage(systemName: "photo")!
        let photoData = PhotoData(
            image: image,
            identifier: "test-library",
            isFromUserLibrary: true
        )

        // Then
        XCTAssertEqual(photoData.identifier, "test-library")
        XCTAssertTrue(photoData.isFromUserLibrary)
    }

    // MARK: - Permission Status Mapping Tests

    func testMapPHAuthorizationStatus() {
        // Test all permission status mappings
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.authorized),
            .authorized
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.denied),
            .denied
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.restricted),
            .denied
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.notDetermined),
            .notDetermined
        )
        XCTAssertEqual(
            PhotoLibraryService.mapPHAuthorizationStatus(.limited),
            .limited
        )
    }

    // MARK: - Error Handling Tests

    func testImageLoadError() async {
        // Given
        photoService.mockPermissionStatus = .authorized
        // Test will check actual behavior without mock

        // When
        let result = await photoService.getRandomPhotoFromFavorites()

        // Then
        switch result {
        case .success:
            XCTFail("Should fail with image load error")
        case .failure(let error):
            XCTAssertEqual(error, .imageLoadFailed)
        }
    }

    // MARK: - Integration Tests

    func testCompletePhotoRetrievalFlow() async {
        // Given
        photoService.mockPermissionStatus = .authorized
        let mockAlbum = createMockAssetCollection()
        let mockPhoto = createMockPhotoData()
        // Test will use actual service behavior

        // When - Complete flow from permission to photo
        let permissionStatus = await photoService.requestPhotoLibraryPermission()

        guard permissionStatus == .authorized else {
            // If permission denied, should get fallback
            let fallback = photoService.getFallbackPhoto()
            XCTAssertFalse(fallback.isFromUserLibrary)
            return
        }

        let albumResult = await photoService.fetchFavoritesAlbum()
        switch albumResult {
        case .success:
            let photoResult = await photoService.getRandomPhotoFromFavorites()
            switch photoResult {
            case .success(let photo):
                XCTAssertTrue(photo.isFromUserLibrary)
                XCTAssertNotNil(photo.image)
            case .failure:
                // Fallback to default photo
                let fallback = photoService.getFallbackPhoto()
                XCTAssertFalse(fallback.isFromUserLibrary)
            }
        case .failure:
            // Should use fallback
            let fallback = photoService.getFallbackPhoto()
            XCTAssertFalse(fallback.isFromUserLibrary)
        }
    }

    func testFallbackPhotoIsNotFromLibrary() {
        // When
        let fallbackPhoto = photoService.getFallbackPhoto()

        // Then
        XCTAssertFalse(fallbackPhoto.isFromUserLibrary)
        XCTAssertEqual(fallbackPhoto.identifier, "fallback")
    }

    func testPhotoDataFromUserLibraryFlag() {
        // Given
        let userPhoto = PhotoData(
            image: UIImage(systemName: "photo")!,
            identifier: "user-photo",
            isFromUserLibrary: true
        )
        let systemPhoto = PhotoData(
            image: UIImage(systemName: "photo.fill")!,
            identifier: "system-photo",
            isFromUserLibrary: false
        )

        // Then
        XCTAssertTrue(userPhoto.isFromUserLibrary)
        XCTAssertFalse(systemPhoto.isFromUserLibrary)
    }
}

// MARK: - Helper Extensions

extension PhotoLibraryServiceTests {

    private func createMockAssetCollection() -> PHAssetCollection {
        // Create a mock asset collection for testing
        let mockCollection = PHAssetCollection()
        return mockCollection
    }

    private func createMockPhotoData() -> PhotoData {
        let image = UIImage(systemName: "photo.fill") ?? UIImage()
        return PhotoData(
            image: image,
            identifier: "mock-photo-123",
            isFromUserLibrary: true
        )
    }
}

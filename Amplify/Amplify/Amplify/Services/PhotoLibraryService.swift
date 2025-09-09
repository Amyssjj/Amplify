//
//  PhotoLibraryService.swift
//  Amplify
//
//  Service for managing photo library access and photo selection
//

import Foundation
import Photos
import UIKit

// MARK: - Photo Library Service Protocol

@MainActor
protocol PhotoLibraryServiceProtocol: ObservableObject {
    func requestPhotoLibraryPermission() async -> PhotoLibraryPermissionStatus
    func fetchFavoritesAlbum() async -> Result<PHAssetCollection, PhotoLibraryError>
    func getRandomPhotoFromFavorites() async -> Result<PhotoData, PhotoLibraryError>
    func getFallbackPhoto() -> PhotoData
}

// MARK: - Photo Library Service Implementation

@MainActor
class PhotoLibraryService: ObservableObject, PhotoLibraryServiceProtocol {

    // MARK: - Testing Support
    var mockPermissionStatus: PhotoLibraryPermissionStatus?
    var mockFavoritePhotos: [PHAsset] = []
    var mockRecentPhotos: [PHAsset] = []

    // MARK: - Public Methods

    func requestPhotoLibraryPermission() async -> PhotoLibraryPermissionStatus {
        if let mockStatus = mockPermissionStatus {
            return mockStatus
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    continuation.resume(returning: Self.mapPHAuthorizationStatus(status))
                }
            }
        }
    }

    func fetchFavoritesAlbum() async -> Result<PHAssetCollection, PhotoLibraryError> {
        let permissionStatus = await requestPhotoLibraryPermission()

        guard permissionStatus == .authorized || permissionStatus == .limited else {
            return .failure(.permissionDenied)
        }

        let fetchOptions = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumFavorites,
            options: fetchOptions
        )

        guard let favoritesAlbum = collections.firstObject else {
            return .failure(.favoritesAlbumNotFound)
        }

        return .success(favoritesAlbum)
    }

    func getRandomPhotoFromFavorites() async -> Result<PhotoData, PhotoLibraryError> {
        // Check for mock data first (for testing)
        if !mockFavoritePhotos.isEmpty {
            let randomPhoto = mockFavoritePhotos.randomElement()!
            let image = UIImage(systemName: "photo") ?? UIImage()
            return .success(
                PhotoData(
                    image: image,
                    identifier: randomPhoto.localIdentifier,
                    isFromUserLibrary: true
                ))
        }

        let albumResult = await fetchFavoritesAlbum()

        switch albumResult {
        case .success(let album):
            let photos = PHAsset.fetchAssets(in: album, options: nil)

            if photos.count == 0 {
                // Fallback to recent photos if favorites is empty
                return await getRandomPhotoFromRecent()
            }

            let randomIndex = Int.random(in: 0..<photos.count)
            let asset = photos.object(at: randomIndex)

            return await loadImage(from: asset)

        case .failure(let error):
            if error == .permissionDenied {
                return .success(getFallbackPhoto())
            }
            return .failure(error)
        }
    }

    func getFallbackPhoto() -> PhotoData {
        // Return a curated fallback image when permission is denied
        let fallbackImage = UIImage(systemName: "mountain.2.fill") ?? UIImage()
        return PhotoData(
            image: fallbackImage,
            identifier: "fallback-photo",
            isFromUserLibrary: false
        )
    }

    // MARK: - Private Methods

    private func getRandomPhotoFromRecent() async -> Result<PhotoData, PhotoLibraryError> {
        // Check for mock data first (for testing)
        if !mockRecentPhotos.isEmpty {
            let randomPhoto = mockRecentPhotos.randomElement()!
            let image = UIImage(systemName: "photo") ?? UIImage()
            return .success(
                PhotoData(
                    image: image,
                    identifier: randomPhoto.localIdentifier,
                    isFromUserLibrary: true
                ))
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 30  // Last 30 photos

        let recentPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        guard recentPhotos.count > 0 else {
            return .success(getFallbackPhoto())
        }

        let randomIndex = Int.random(in: 0..<recentPhotos.count)
        let asset = recentPhotos.object(at: randomIndex)

        return await loadImage(from: asset)
    }

    private func loadImage(from asset: PHAsset) async -> Result<PhotoData, PhotoLibraryError> {
        return await withCheckedContinuation { continuation in
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 400, height: 400),
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    let photoData = PhotoData(
                        image: image,
                        identifier: asset.localIdentifier,
                        isFromUserLibrary: true
                    )
                    continuation.resume(returning: .success(photoData))
                } else {
                    continuation.resume(returning: .failure(.imageLoadFailed))
                }
            }
        }
    }

    // MARK: - Static Methods

    static func mapPHAuthorizationStatus(_ status: PHAuthorizationStatus)
        -> PhotoLibraryPermissionStatus
    {
        switch status {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

// MARK: - Supporting Types

enum PhotoLibraryPermissionStatus {
    case authorized
    case limited
    case denied
    case notDetermined
}

enum PhotoLibraryError: Error, Equatable {
    case permissionDenied
    case favoritesAlbumNotFound
    case imageLoadFailed
    case noPhotosAvailable
}

struct PhotoData {
    let image: UIImage
    let identifier: String
    let isFromUserLibrary: Bool
}

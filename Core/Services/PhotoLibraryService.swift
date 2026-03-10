//
//  PhotoLibraryService.swift
//  CloudToDisk
//
//  Interfaces with PhotoKit to access and export photos
//

import Photos
import Foundation
import AVFoundation

class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()

    private init() {}

    // Photo Enumeration

    func getTotalPhotoCount() -> Int {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAllBurstAssets = false

        let allPhotos = PHAsset.fetchAssets(with: options)
        return allPhotos.count
    }

    func fetchAllAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAllBurstAssets = false
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        return PHAsset.fetchAssets(with: options)
    }

    func fetchAssetsNotBackedUp(backedUpIdentifiers: Set<String>) -> [PHAsset] {
        let allAssets = fetchAllAssets()
        var assetsToBackup: [PHAsset] = []

        allAssets.enumerateObjects { asset, _, _ in
            if !backedUpIdentifiers.contains(asset.localIdentifier) {
                assetsToBackup.append(asset)
            }
        }

        return assetsToBackup
    }

    // Asset Export

    func exportAsset(
        _ asset: PHAsset,
        to destinationURL: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        switch asset.mediaType {
        case .image:
            try await exportImage(asset, to: destinationURL, progressHandler: progressHandler)
        case .video:
            try await exportVideo(asset, to: destinationURL, progressHandler: progressHandler)
        default:
            throw PhotoExportError.unsupportedMediaType
        }
    }

    private func exportImage(
        _ asset: PHAsset,
        to destinationURL: URL,
        progressHandler: ((Double) -> Void)?
    ) async throws {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.progressHandler = { progress, _, _, _ in
            progressHandler?(progress)
        }

        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, dataUTI, orientation, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let imageData = data else {
                    continuation.resume(throwing: PhotoExportError.noData)
                    return
                }

                do {
                    try imageData.write(to: destinationURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func exportVideo(
        _ asset: PHAsset,
        to destinationURL: URL,
        progressHandler: ((Double) -> Void)?
    ) async throws {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.progressHandler = { progress, _, _, _ in
            progressHandler?(progress)
        }

        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let urlAsset = avAsset as? AVURLAsset else {
                    continuation.resume(throwing: PhotoExportError.noData)
                    return
                }

                do {
                    let videoData = try Data(contentsOf: urlAsset.url)
                    try videoData.write(to: destinationURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Live Photos

    func isLivePhoto(_ asset: PHAsset) -> Bool {
        return (asset.mediaSubtypes.contains(.photoLive))
    }

    func exportLivePhoto(
        _ asset: PHAsset,
        imageURL: URL,
        videoURL: URL
    ) async throws {
        // Export image component
        try await exportImage(asset, to: imageURL, progressHandler: nil)

        // Export video component
        let resources = PHAssetResource.assetResources(for: asset)
        if let videoResource = resources.first(where: { $0.type == .pairedVideo }) {
            try await exportLivePhotoVideo(videoResource, to: videoURL)
        }
    }

    private func exportLivePhotoVideo(_ resource: PHAssetResource, to destinationURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: destinationURL,
                options: nil
            ) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // Utilities

    func getOriginalFilename(for asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            return resource.originalFilename
        }
        return "unknown_\(asset.localIdentifier).jpg"
    }

    func getFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        var totalSize: Int64 = 0

        for resource in resources {
            if let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }
}

// Errors

enum PhotoExportError: LocalizedError {
    case unsupportedMediaType
    case noData
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedMediaType:
            return "Unsupported media type"
        case .noData:
            return "No data available for export"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

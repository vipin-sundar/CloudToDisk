//
//  PhotoLibraryService.swift
//  CloudToDisk
//
//  Interfaces with PhotoKit to access and export photos
//

import Photos
import Foundation
import AVFoundation

// Progress information for export operations
struct ExportProgress {
    var progress: Double
    var isDownloadingFromiCloud: Bool
    var downloadAttempt: Int
}

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
        progressHandler: ((ExportProgress) -> Void)? = nil
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
        progressHandler: ((ExportProgress) -> Void)?
    ) async throws {
        // Retry up to 3 times for iCloud downloads
        var lastError: Error?

        for attempt in 1...3 {
            do {
                try await exportImageWithRetry(asset, to: destinationURL, attempt: attempt, progressHandler: progressHandler)
                return // Success!
            } catch PhotoExportError.iCloudDownloadFailed {
                lastError = PhotoExportError.iCloudDownloadFailed

                if attempt < 3 {
                    print("⏳ iCloud download attempt \(attempt) failed, retrying in \(attempt * 2) seconds...")
                    // Wait before retry (exponential backoff: 2s, 4s)
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 2_000_000_000))
                } else {
                    print("❌ iCloud download failed after 3 attempts")
                }
            } catch {
                // Other errors, don't retry
                throw error
            }
        }

        // All retries failed
        throw lastError ?? PhotoExportError.iCloudDownloadFailed
    }

    private func exportImageWithRetry(
        _ asset: PHAsset,
        to destinationURL: URL,
        attempt: Int,
        progressHandler: ((ExportProgress) -> Void)?
    ) async throws {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        // Version to prioritize: try to get high quality even if takes time
        options.version = .current

        options.progressHandler = { progress, error, stop, info in
            // Report detailed progress with iCloud download info
            let exportProgress = ExportProgress(
                progress: progress,
                isDownloadingFromiCloud: true,  // If this handler is called, we're downloading
                downloadAttempt: attempt
            )
            progressHandler?(exportProgress)

            // Log iCloud download progress
            if progress > 0 && progress < 1.0 {
                print("📥 iCloud downloading: \(Int(progress * 100))% (attempt \(attempt))")
            }

            // Check for download errors during progress
            if let error = error {
                print("⚠️ iCloud download error during progress: \(error.localizedDescription)")
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, dataUTI, orientation, info in
                // Check if this is a degraded/preview image (not the full quality)
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    // This is just a preview, wait for the full image
                    print("⏳ Received preview, waiting for full quality image...")
                    return
                }

                // Check if download was cancelled
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    continuation.resume(throwing: PhotoExportError.cancelled)
                    return
                }

                // Check for errors
                if let error = info?[PHImageErrorKey] as? Error {
                    let nsError = error as NSError

                    // Error 3164 = photo not available (in iCloud, download failed/timed out)
                    if nsError.code == 3164 {
                        print("⚠️ Photo in iCloud but download failed (code 3164): \(nsError)")
                        continuation.resume(throwing: PhotoExportError.iCloudDownloadFailed)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                // Check if data is available
                guard let imageData = data else {
                    // Check if photo is in iCloud but not downloaded yet
                    if let inCloud = info?[PHImageResultIsInCloudKey] as? Bool, inCloud {
                        print("⚠️ Photo is in iCloud but data not available (attempt \(attempt))")
                        continuation.resume(throwing: PhotoExportError.iCloudDownloadFailed)
                    } else {
                        continuation.resume(throwing: PhotoExportError.noData)
                    }
                    return
                }

                // Write the downloaded image to destination
                do {
                    try imageData.write(to: destinationURL)
                    print("✅ Successfully backed up image (attempt \(attempt))")
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
        progressHandler: ((ExportProgress) -> Void)?
    ) async throws {
        // Retry up to 3 times for iCloud downloads (videos may be large)
        var lastError: Error?

        for attempt in 1...3 {
            do {
                try await exportVideoWithRetry(asset, to: destinationURL, attempt: attempt, progressHandler: progressHandler)
                return // Success!
            } catch PhotoExportError.iCloudDownloadFailed {
                lastError = PhotoExportError.iCloudDownloadFailed

                if attempt < 3 {
                    print("⏳ iCloud video download attempt \(attempt) failed, retrying in \(attempt * 3) seconds...")
                    // Wait longer for videos (exponential backoff: 3s, 6s)
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 3_000_000_000))
                } else {
                    print("❌ iCloud video download failed after 3 attempts")
                }
            } catch {
                // Other errors, don't retry
                throw error
            }
        }

        // All retries failed
        throw lastError ?? PhotoExportError.iCloudDownloadFailed
    }

    private func exportVideoWithRetry(
        _ asset: PHAsset,
        to destinationURL: URL,
        attempt: Int,
        progressHandler: ((ExportProgress) -> Void)?
    ) async throws {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current

        options.progressHandler = { progress, error, stop, info in
            // Report detailed progress with iCloud download info
            let exportProgress = ExportProgress(
                progress: progress,
                isDownloadingFromiCloud: true,  // If this handler is called, we're downloading
                downloadAttempt: attempt
            )
            progressHandler?(exportProgress)

            // Log iCloud download progress for videos
            if progress > 0 && progress < 1.0 {
                print("📥 iCloud downloading video: \(Int(progress * 100))% (attempt \(attempt))")
            }

            // Check for download errors during progress
            if let error = error {
                print("⚠️ iCloud video download error during progress: \(error.localizedDescription)")
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
                // Check if this is a degraded/preview version
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    print("⏳ Received preview, waiting for full quality video...")
                    return
                }

                // Check if download was cancelled
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    continuation.resume(throwing: PhotoExportError.cancelled)
                    return
                }

                // Check for errors
                if let error = info?[PHImageErrorKey] as? Error {
                    let nsError = error as NSError

                    // Error 3164 = video not available (in iCloud, download failed)
                    if nsError.code == 3164 {
                        print("⚠️ Video in iCloud but download failed (code 3164): \(nsError)")
                        continuation.resume(throwing: PhotoExportError.iCloudDownloadFailed)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let urlAsset = avAsset as? AVURLAsset else {
                    // Check if video is in iCloud but not downloaded yet
                    if let inCloud = info?[PHImageResultIsInCloudKey] as? Bool, inCloud {
                        print("⚠️ Video is in iCloud but data not available (attempt \(attempt))")
                        continuation.resume(throwing: PhotoExportError.iCloudDownloadFailed)
                    } else {
                        continuation.resume(throwing: PhotoExportError.noData)
                    }
                    return
                }

                do {
                    let videoData = try Data(contentsOf: urlAsset.url)
                    try videoData.write(to: destinationURL)
                    print("✅ Successfully backed up video (attempt \(attempt))")
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
    case iCloudDownloadFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unsupportedMediaType:
            return "Unsupported media type"
        case .noData:
            return "No data available for export"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .iCloudDownloadFailed:
            return "Photo is in iCloud but download failed. Check internet connection or enable 'Download Originals to this Mac' in Photos settings."
        case .cancelled:
            return "Export was cancelled"
        }
    }
}

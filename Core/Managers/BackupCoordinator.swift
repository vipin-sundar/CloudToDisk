//
//  BackupCoordinator.swift
//  CloudToDisk
//
//  Orchestrates the backup process
//

import Foundation
import Photos
import Combine

// Timeout error
struct TimeoutError: Error {}

// Timeout helper
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

class BackupCoordinator: ObservableObject {
    static let shared = BackupCoordinator()

    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentProgress: BackupProgress = BackupProgress()
    @Published var currentFile: String = ""
    @Published var errorMessage: String?

    private var backupTask: Task<Void, Never>?
    private let photoLibrary = PhotoLibraryService.shared
    private let fileManager = FileManagerService.shared
    private let stateManager = BackupStateManager.shared

    private let batchSize = 10  // Reduced from 20 to prevent memory issues
    private let maxConcurrentExports = 2  // Reduced from 4 to prevent freezing

    private init() {}

    // MARK: - Backup Control

    func startBackup() {
        guard !isRunning else { return }

        // Check permissions
        guard PermissionService.shared.isAuthorized else {
            errorMessage = "Photos permission not granted"
            return
        }

        // Check destination path
        let config = stateManager.getOrCreateConfiguration()
        guard let destinationPath = config.destinationPath, !destinationPath.isEmpty else {
            errorMessage = "Please select a destination folder in Settings"
            return
        }

        // Validate destination
        do {
            try fileManager.validateDestinationPath(destinationPath)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isRunning = true
        isPaused = false
        errorMessage = nil
        stateManager.setBackupActive(true)

        backupTask = Task {
            await performBackup()
        }
    }

    func pauseBackup() {
        isPaused = true
        backupTask?.cancel()
        stateManager.setBackupActive(false)
    }

    func resumeBackup() {
        guard isPaused else { return }
        isPaused = false
        startBackup()
    }

    func stopBackup() {
        isRunning = false
        isPaused = false
        backupTask?.cancel()
        stateManager.setBackupActive(false)
    }

    // Backup Execution

    private func performBackup() async {
        let config = stateManager.getOrCreateConfiguration()
        guard let destinationPath = config.destinationPath else {
            await setError("No destination path configured")
            return
        }

        // Get total photo count
        let totalPhotos = photoLibrary.getTotalPhotoCount()
        await MainActor.run {
            currentProgress.totalItems = totalPhotos
            stateManager.updateConfiguration(totalPhotos: Int64(totalPhotos))
        }

        // Get already backed up identifiers
        let backedUpIdentifiers = stateManager.getAllBackedUpAssetIdentifiers()

        // Get assets that need backing up
        let assetsToBackup = photoLibrary.fetchAssetsNotBackedUp(backedUpIdentifiers: backedUpIdentifiers)

        await MainActor.run {
            currentProgress.remainingItems = assetsToBackup.count
            currentProgress.completedItems = totalPhotos - assetsToBackup.count
        }

        // Process in batches
        var currentIndex = 0
        var batchNumber = 0

        while currentIndex < assetsToBackup.count && isRunning && !isPaused {
            let endIndex = min(currentIndex + batchSize, assetsToBackup.count)
            let batch = Array(assetsToBackup[currentIndex..<endIndex])

            batchNumber += 1
            print("📦 Processing batch \(batchNumber): items \(currentIndex)-\(endIndex) of \(assetsToBackup.count)")

            await processBatch(batch, destinationPath: destinationPath)

            // Force memory cleanup every 5 batches (every 50 items)
            if batchNumber % 5 == 0 {
                print("🧹 Cleaning up memory after \(batchNumber) batches...")
                await Task.yield()
            }

            currentIndex = endIndex
        }

        await MainActor.run {
            isRunning = false
            stateManager.setBackupActive(false)
            currentFile = ""

            if !isPaused {
                currentProgress.isComplete = true
            }
        }
    }

    private func processBatch(_ assets: [PHAsset], destinationPath: String) async {
        // Use autoreleasepool to manage memory for each batch
        await withTaskGroup(of: Void.self) { group in
            var activeCount = 0

            for asset in assets {
                // Limit concurrent operations
                while activeCount >= maxConcurrentExports {
                    await group.next()
                    activeCount -= 1
                }

                group.addTask {
                    // Process asset (memory is managed by periodic cleanup)
                    await self.backupAsset(asset, to: destinationPath)
                }
                activeCount += 1

                // Check if paused
                if isPaused || !isRunning {
                    break
                }
            }

            // Wait for remaining tasks
            await group.waitForAll()
        }

        // Force memory cleanup after each batch
        await Task.yield()  // Give system time to clean up
    }

    private func backupAsset(_ asset: PHAsset, to destinationPath: String) async {
        let filename = photoLibrary.getOriginalFilename(for: asset)

        await MainActor.run {
            currentFile = filename
        }

        // Add timeout to prevent hanging forever (5 minutes per file)
        do {
            try await withTimeout(seconds: 300) {
                try await self.performBackupWithRetry(asset, filename: filename, destinationPath: destinationPath)
            }
        } catch is TimeoutError {
            print("⏱️ Timeout backing up \(filename) - skipping after 5 minutes")
            await MainActor.run {
                self.currentProgress.errorCount += 1
            }
        } catch {
            print("❌ Error backing up \(filename): \(error.localizedDescription)")
            await MainActor.run {
                self.currentProgress.errorCount += 1
            }
        }

        // Update progress
        await MainActor.run {
            currentProgress.completedItems += 1
            currentProgress.remainingItems -= 1
            currentProgress.calculateProgress()

            // Reset download state after completing this file
            currentProgress.isDownloadingFromiCloud = false
            currentProgress.iCloudDownloadProgress = 0.0
            currentProgress.currentDownloadAttempt = 0
        }
    }

    private func performBackupWithRetry(_ asset: PHAsset, filename: String, destinationPath: String) async throws {
        // Get destination directory based on date
        let directoryURL = try fileManager.getDatePath(for: asset.creationDate, basePath: destinationPath)

        // Handle Live Photos
        if photoLibrary.isLivePhoto(asset) {
            try await backupLivePhoto(asset, to: directoryURL, filename: filename)
        } else {
            try await backupRegularAsset(asset, to: directoryURL, filename: filename)
        }

        // Save to database (do this in background to avoid blocking)
        let mediaType: Int16 = asset.mediaType == .video ? 1 : 0
        let fileSize = photoLibrary.getFileSize(for: asset)

        stateManager.saveBackupRecord(
            assetIdentifier: asset.localIdentifier,
            originalFilename: filename,
            creationDate: asset.creationDate,
            mediaType: mediaType,
            fileSize: fileSize,
            destinationPath: directoryURL.path
        )

        // Update configuration every 10 items
        await MainActor.run {
            if currentProgress.completedItems % 10 == 0 {
                stateManager.updateConfiguration(backedUpCount: Int64(currentProgress.completedItems + 1))
            }
        }
    }

    private func backupRegularAsset(_ asset: PHAsset, to directory: URL, filename: String) async throws {
        let destinationURL = fileManager.getUniqueFilePath(in: directory, filename: filename)

        // Create temp file for export
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try await photoLibrary.exportAsset(asset, to: tempURL) { exportProgress in
            Task { @MainActor in
                self.currentProgress.currentItemProgress = exportProgress.progress
                self.currentProgress.isDownloadingFromiCloud = exportProgress.isDownloadingFromiCloud
                self.currentProgress.iCloudDownloadProgress = exportProgress.progress
                self.currentProgress.currentDownloadAttempt = exportProgress.downloadAttempt
            }
        }

        // Move to final destination
        try fileManager.copyFile(from: tempURL, to: destinationURL)

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }

    private func backupLivePhoto(_ asset: PHAsset, to directory: URL, filename: String) async throws {
        let nameWithoutExtension = (filename as NSString).deletingPathExtension
        let fileExtension = (filename as NSString).pathExtension

        let imageFilename = "\(nameWithoutExtension).\(fileExtension)"
        let videoFilename = "\(nameWithoutExtension).MOV"

        let imageURL = fileManager.getUniqueFilePath(in: directory, filename: imageFilename)
        let videoURL = fileManager.getUniqueFilePath(in: directory, filename: videoFilename)

        // Create temp files
        let tempImageURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tempVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try await photoLibrary.exportLivePhoto(asset, imageURL: tempImageURL, videoURL: tempVideoURL)

        // Move to final destinations
        try fileManager.copyFile(from: tempImageURL, to: imageURL)
        try fileManager.copyFile(from: tempVideoURL, to: videoURL)

        // Clean up temp files
        try? FileManager.default.removeItem(at: tempImageURL)
        try? FileManager.default.removeItem(at: tempVideoURL)
    }

    // Helpers

    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
        isRunning = false
        stateManager.setBackupActive(false)
    }

    @MainActor
    private func incrementErrorCount() {
        currentProgress.errorCount += 1
    }
}

// Progress Model

struct BackupProgress {
    var totalItems: Int = 0
    var completedItems: Int = 0
    var remainingItems: Int = 0
    var errorCount: Int = 0
    var currentItemProgress: Double = 0.0
    var overallProgress: Double = 0.0
    var isComplete: Bool = false

    // iCloud download progress
    var isDownloadingFromiCloud: Bool = false
    var iCloudDownloadProgress: Double = 0.0
    var currentDownloadAttempt: Int = 0

    mutating func calculateProgress() {
        if totalItems > 0 {
            overallProgress = Double(completedItems) / Double(totalItems)
        }
    }

    var percentComplete: Int {
        return Int(overallProgress * 100)
    }
}

//
//  BackupStateManager.swift
//  CloudToDisk
//
//  Manages backup state persistence via Core Data
//

import CoreData
import Foundation
import Combine

class BackupStateManager: ObservableObject {
    static let shared = BackupStateManager()

    private let context: NSManagedObjectContext

    private init() {
        self.context = PersistenceController.shared.viewContext
    }

    // Configuration Management

    func getOrCreateConfiguration() -> BackupConfiguration {
        let request: NSFetchRequest<BackupConfiguration> = BackupConfiguration.fetchRequest()

        do {
            let results = try context.fetch(request)
            if let config = results.first {
                return config
            }
        } catch {
            print("Error fetching configuration: \(error)")
        }

        // Create new configuration
        let config = BackupConfiguration(context: context)
        config.id = UUID()
        config.isActive = false
        config.backedUpCount = 0
        config.totalPhotosCount = 0

        saveContext()
        return config
    }

    func updateConfiguration(destinationPath: String? = nil, totalPhotos: Int64? = nil, backedUpCount: Int64? = nil) {
        let config = getOrCreateConfiguration()

        if let path = destinationPath {
            config.destinationPath = path
        }
        if let total = totalPhotos {
            config.totalPhotosCount = total
        }
        if let backed = backedUpCount {
            config.backedUpCount = backed
        }
        config.lastBackupDate = Date()

        saveContext()
    }

    func setBackupActive(_ active: Bool) {
        let config = getOrCreateConfiguration()
        config.isActive = active
        saveContext()
    }

    func setBackupInactive() {
        setBackupActive(false)
    }

    func isBackupActive() -> Bool {
        return getOrCreateConfiguration().isActive
    }

    // Backup Records

    func isAssetBackedUp(_ assetIdentifier: String) -> Bool {
        let request: NSFetchRequest<BackupRecord> = BackupRecord.fetchRequest()
        request.predicate = NSPredicate(format: "assetIdentifier == %@", assetIdentifier)
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking asset: \(error)")
            return false
        }
    }

    func getAllBackedUpAssetIdentifiers() -> Set<String> {
        let request: NSFetchRequest<BackupRecord> = BackupRecord.fetchRequest()
        request.propertiesToFetch = ["assetIdentifier"]

        do {
            let records = try context.fetch(request)
            return Set(records.compactMap { $0.assetIdentifier })
        } catch {
            print("Error fetching backed up identifiers: \(error)")
            return Set()
        }
    }

    func saveBackupRecord(
        assetIdentifier: String,
        originalFilename: String,
        creationDate: Date?,
        mediaType: Int16,
        fileSize: Int64,
        destinationPath: String,
        checksum: String? = nil
    ) {
        // Check if already exists
        if isAssetBackedUp(assetIdentifier) {
            return
        }

        let record = BackupRecord(context: context)
        record.assetIdentifier = assetIdentifier
        record.originalFilename = originalFilename
        record.creationDate = creationDate
        record.mediaType = mediaType
        record.fileSize = fileSize
        record.destinationPath = destinationPath
        record.backupDate = Date()
        record.checksum = checksum

        saveContext()
    }

    func getBackedUpCount() -> Int64 {
        let request: NSFetchRequest<BackupRecord> = BackupRecord.fetchRequest()

        do {
            return Int64(try context.count(for: request))
        } catch {
            print("Error counting backed up records: \(error)")
            return 0
        }
    }

    func deleteAllBackupRecords() {
        let request: NSFetchRequest<NSFetchRequestResult> = BackupRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("Error deleting backup records: \(error)")
        }
    }

    func resetBackupHistory() {
        // Delete all backup records
        deleteAllBackupRecords()

        // Reset configuration counters
        let config = getOrCreateConfiguration()
        config.backedUpCount = 0
        config.lastBackupDate = nil

        saveContext()

        print("✅ Backup history cleared - ready to start fresh")
    }

    // Helper

    private func saveContext() {
        PersistenceController.shared.saveContext()
    }
}

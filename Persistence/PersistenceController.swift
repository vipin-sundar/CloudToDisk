//
//  PersistenceController.swift
//  CloudToDisk
//
//  Core Data stack management
//

import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // Main context for UI
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    // Background context for batch operations
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    private init() {
        container = NSPersistentContainer(name: "CloudToDisk")

        // Configure for better performance
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        // Configure contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // Save context with error handling
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // Save background context
    func saveBackgroundContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving background context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // Create preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController()
        let context = controller.container.viewContext

        // Add sample data for previews
        let config = BackupConfiguration(context: context)
        config.id = UUID()
        config.destinationPath = "/Volumes/BackupSSD/Photos"
        config.totalPhotosCount = 5000
        config.backedUpCount = 1234
        config.isActive = false

        do {
            try context.save()
        } catch {
            print("Preview error: \(error)")
        }

        return controller
    }()
}

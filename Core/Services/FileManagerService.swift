//
//  FileManagerService.swift
//  CloudToDisk
//
//  Manages file operations for backup
//

import Foundation

class FileManagerService {
    static let shared = FileManagerService()

    private let fileManager = FileManager.default

    private init() {}

    // Directory Management

    func createDateBasedDirectory(at basePath: String, year: Int, month: Int) throws -> URL {
        let datePathComponent = String(format: "%04d/%02d", year, month)
        let fullPath = (basePath as NSString).appendingPathComponent(datePathComponent)
        let url = URL(fileURLWithPath: fullPath)

        if !fileManager.fileExists(atPath: fullPath) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }

        return url
    }

    func createOthersDirectory(at basePath: String) throws -> URL {
        let othersPath = (basePath as NSString).appendingPathComponent("Others")
        let url = URL(fileURLWithPath: othersPath)

        if !fileManager.fileExists(atPath: othersPath) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }

        return url
    }

    func getDatePath(for date: Date?, basePath: String) throws -> URL {
        guard let date = date else {
            return try createOthersDirectory(at: basePath)
        }

        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        return try createDateBasedDirectory(at: basePath, year: year, month: month)
    }

    // File Operations

    func getUniqueFilePath(in directory: URL, filename: String) -> URL {
        var destinationURL = directory.appendingPathComponent(filename)
        var counter = 1

        // If file exists, append counter
        while fileManager.fileExists(atPath: destinationURL.path) {
            let nameWithoutExtension = (filename as NSString).deletingPathExtension
            let fileExtension = (filename as NSString).pathExtension
            let newFilename = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            destinationURL = directory.appendingPathComponent(newFilename)
            counter += 1
        }

        return destinationURL
    }

    func copyFile(from source: URL, to destination: URL) throws {
        // Ensure destination directory exists
        let destinationDirectory = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        // Copy file
        try fileManager.copyItem(at: source, to: destination)
    }

    // Disk Space

    func getAvailableDiskSpace(at path: String) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path)
            if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        } catch {
            print("Error getting disk space: \(error)")
        }
        return nil
    }

    func hasSufficientSpace(at path: String, requiredBytes: Int64) -> Bool {
        guard let availableSpace = getAvailableDiskSpace(at: path) else {
            return false
        }
        // Add 1GB buffer
        let buffer: Int64 = 1_073_741_824
        return availableSpace > (requiredBytes + buffer)
    }

    // Volume Management

    func isVolumeAvailable(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func getVolumeInfo(at path: String) -> VolumeInfo? {
        do {
            let url = URL(fileURLWithPath: path)
            let resourceValues = try url.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])

            return VolumeInfo(
                name: resourceValues.volumeName ?? "Unknown",
                totalCapacity: Int64(resourceValues.volumeTotalCapacity ?? 0),
                availableCapacity: Int64(resourceValues.volumeAvailableCapacity ?? 0)
            )
        } catch {
            print("Error getting volume info: \(error)")
            return nil
        }
    }

    // Path Validation

    func validateDestinationPath(_ path: String) throws {
        // Check if path exists
        guard fileManager.fileExists(atPath: path) else {
            throw FileManagerError.pathDoesNotExist
        }

        // Check if it's a directory
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        guard isDirectory.boolValue else {
            throw FileManagerError.notADirectory
        }

        // Check if writable
        guard fileManager.isWritableFile(atPath: path) else {
            throw FileManagerError.notWritable
        }
    }
}

//  Supporting Types

struct VolumeInfo {
    let name: String
    let totalCapacity: Int64
    let availableCapacity: Int64

    var totalCapacityGB: Double {
        return Double(totalCapacity) / 1_073_741_824
    }

    var availableCapacityGB: Double {
        return Double(availableCapacity) / 1_073_741_824
    }

    var usedCapacityGB: Double {
        return totalCapacityGB - availableCapacityGB
    }
}

enum FileManagerError: LocalizedError {
    case pathDoesNotExist
    case notADirectory
    case notWritable
    case insufficientSpace
    case volumeNotAvailable

    var errorDescription: String? {
        switch self {
        case .pathDoesNotExist:
            return "The selected path does not exist"
        case .notADirectory:
            return "The selected path is not a directory"
        case .notWritable:
            return "The selected directory is not writable"
        case .insufficientSpace:
            return "Insufficient disk space available"
        case .volumeNotAvailable:
            return "The backup volume is not available"
        }
    }
}

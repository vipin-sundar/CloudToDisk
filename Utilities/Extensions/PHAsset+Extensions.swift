//
//  PHAsset+Extensions.swift
//  CloudToDisk
//
//  Extensions for PHAsset
//

import Photos

extension PHAsset {
    var isPhoto: Bool {
        return mediaType == .image
    }

    var isVideo: Bool {
        return mediaType == .video
    }

    var isLivePhoto: Bool {
        return mediaSubtypes.contains(.photoLive)
    }

    var readableMediaType: String {
        switch mediaType {
        case .image:
            return isLivePhoto ? "Live Photo" : "Photo"
        case .video:
            return "Video"
        case .audio:
            return "Audio"
        default:
            return "Unknown"
        }
    }

    var formattedCreationDate: String {
        guard let date = creationDate else {
            return "Unknown Date"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

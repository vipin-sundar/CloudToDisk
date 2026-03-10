//
//  PermissionService.swift
//  CloudToDisk
//
//  Handles Photos library authorization
//

import Photos
import Foundation
import AppKit

class PermissionService: ObservableObject {
    static let shared = PermissionService()

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        await MainActor.run {
            self.authorizationStatus = status
        }

        return status == .authorized
    }

    var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }

    var needsAuthorization: Bool {
        return authorizationStatus == .notDetermined || authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
            NSWorkspace.shared.open(url)
        }
    }
}

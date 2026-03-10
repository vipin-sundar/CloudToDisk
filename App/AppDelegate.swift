//
//  AppDelegate.swift
//  CloudToDisk
//
//  Manages the menu bar integration and app lifecycle
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("CloudToDisk: App launched!")

        // Initialize menu bar controller
        menuBarController = MenuBarController()
        print("CloudToDisk: MenuBarController initialized")

        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)
        print("CloudToDisk: Activation policy set to accessory")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save any pending state before quit
        BackupStateManager.shared.setBackupInactive()
        PersistenceController.shared.saveContext()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when windows close - we're a menu bar app
        return false
    }
}

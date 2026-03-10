//
//  CloudToDiskApp.swift
//  CloudToDisk
//
//  Main entry point for the CloudToDisk menu bar application
//

import SwiftUI

@main
struct CloudToDiskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var persistenceController = PersistenceController.shared

    var body: some Scene {
        // Menu bar app - no default window
        Settings {
            EmptyView()
        }
    }
}

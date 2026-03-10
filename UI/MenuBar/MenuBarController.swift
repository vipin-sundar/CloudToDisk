//
//  MenuBarController.swift
//  CloudToDisk
//
//  Manages the NSStatusBar menu bar icon and menu
//

import AppKit
import SwiftUI

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var statusWindow: NSWindow?

    @Published var backupState: BackupState = .idle

    enum BackupState {
        case idle
        case running
        case paused
        case completed
        case error(String)

        var iconName: String {
            switch self {
            case .idle: return "cloud"
            case .running: return "arrow.down.to.line.compact"
            case .paused: return "pause.circle"
            case .completed: return "checkmark.circle"
            case .error: return "exclamationmark.triangle"
            }
        }

        var iconColor: NSColor {
            switch self {
            case .idle: return .systemGray
            case .running: return .systemBlue
            case .paused: return .systemOrange
            case .completed: return .systemGreen
            case .error: return .systemRed
            }
        }
    }

    init() {
        print("🔧 MenuBarController: Initializing...")
        setupMenuBar()
        print("✅ MenuBarController: Setup complete")
    }

    private func setupMenuBar() {
        print("📊 MenuBarController: Setting up menu bar...")

        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("📊 MenuBarController: Status item created: \(statusItem != nil ? "✅" : "❌")")

        if let button = statusItem?.button {
            print("📊 MenuBarController: Status item button found")

            // Set up icon (outline cloud)
            updateIcon(for: .idle)
            button.action = #selector(menuBarButtonClicked)
            button.target = self
        } else {
            print("❌ MenuBarController: ERROR - No status item button!")
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open Status", action: #selector(openStatus), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start Backup", action: #selector(startBackup), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Pause Backup", action: #selector(pauseBackup), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit CloudToDisk", action: #selector(quitApp), keyEquivalent: "q"))

        // Set targets for menu items
        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu

        print("✅ MenuBarController: Menu bar setup complete!")
        print("👀 Look for the cloud icon in your top-right menu bar!")
    }

    private func updateIcon(for state: BackupState) {
        if let button = statusItem?.button {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            let image = NSImage(systemSymbolName: state.iconName, accessibilityDescription: "CloudToDisk")
            image?.isTemplate = true

            button.image = image?.withSymbolConfiguration(config)
            button.image?.size = NSSize(width: 18, height: 18)

            // Set tint color
            if let imageView = button.subviews.first(where: { $0 is NSImageView }) as? NSImageView {
                imageView.contentTintColor = state.iconColor
            }
        }
        backupState = state
    }

    @objc private func menuBarButtonClicked() {
        // Menu will show automatically
    }

    @objc private func openStatus() {
        showStatusWindow()
    }

    @objc private func startBackup() {
        updateIcon(for: .running)
        BackupCoordinator.shared.startBackup()
    }

    @objc private func pauseBackup() {
        updateIcon(for: .paused)
        BackupCoordinator.shared.pauseBackup()
    }

    @objc private func openSettings() {
        showSettingsWindow()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func showStatusWindow() {
        if statusWindow == nil {
            let contentView = StatusView()
            let hostingController = NSHostingController(rootView: contentView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "CloudToDisk Status"
            window.setContentSize(NSSize(width: 400, height: 300))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.center()

            statusWindow = window
        }

        statusWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showSettingsWindow() {
        let contentView = SettingsView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "CloudToDisk Settings"
        window.setContentSize(NSSize(width: 500, height: 400))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateState(_ state: BackupState) {
        DispatchQueue.main.async { [weak self] in
            self?.updateIcon(for: state)
        }
    }
}

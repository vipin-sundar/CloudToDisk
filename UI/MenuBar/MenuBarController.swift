//
//  MenuBarController.swift
//  CloudToDisk
//
//  Manages the NSStatusBar menu bar icon and menu
//

import AppKit
import SwiftUI
import Combine

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var statusWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

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
        observeBackupProgress()
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
            updateDisplay(progress: BackupCoordinator.shared.currentProgress, isRunning: false)
            button.action = #selector(menuBarButtonClicked)
            button.target = self
        } else {
            print("❌ MenuBarController: ERROR - No status item button!")
        }

        updateMenu()

        print("✅ MenuBarController: Menu bar setup complete!")
        print("👀 Look for the cloud icon in your top-right menu bar!")
    }

    private func observeBackupProgress() {
        // Observe backup state changes
        BackupCoordinator.shared.$isRunning
            .sink { [weak self] isRunning in
                self?.updateDisplay(
                    progress: BackupCoordinator.shared.currentProgress,
                    isRunning: isRunning
                )
                self?.updateMenu()
            }
            .store(in: &cancellables)

        BackupCoordinator.shared.$isPaused
            .sink { [weak self] _ in
                self?.updateDisplay(
                    progress: BackupCoordinator.shared.currentProgress,
                    isRunning: BackupCoordinator.shared.isRunning
                )
                self?.updateMenu()
            }
            .store(in: &cancellables)

        BackupCoordinator.shared.$currentProgress
            .sink { [weak self] progress in
                self?.updateDisplay(
                    progress: progress,
                    isRunning: BackupCoordinator.shared.isRunning
                )
            }
            .store(in: &cancellables)
    }

    private func updateDisplay(progress: BackupProgress, isRunning: Bool) {
        guard let button = statusItem?.button else { return }

        // Determine state
        let state: BackupState
        if BackupCoordinator.shared.isPaused {
            state = .paused
        } else if isRunning {
            state = .running
        } else if progress.isComplete && progress.completedItems > 0 {
            state = .completed
        } else {
            state = .idle
        }

        // Update icon
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let image = NSImage(systemSymbolName: state.iconName, accessibilityDescription: "CloudToDisk")
        image?.isTemplate = true

        button.image = image?.withSymbolConfiguration(config)
        button.image?.size = NSSize(width: 18, height: 18)

        // Set tint color
        if let imageView = button.subviews.first(where: { $0 is NSImageView }) as? NSImageView {
            imageView.contentTintColor = state.iconColor
        }

        // Update title with count
        if progress.totalItems > 0 {
            let countText = " \(progress.completedItems)/\(progress.totalItems)"
            button.title = countText
        } else {
            button.title = ""
        }

        backupState = state
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Open Status
        menu.addItem(NSMenuItem(title: "Open Status", action: #selector(openStatus), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())

        // Dynamic backup action based on state
        let coordinator = BackupCoordinator.shared

        if coordinator.isRunning {
            // Show Pause when running
            menu.addItem(NSMenuItem(title: "Pause Backup", action: #selector(pauseBackup), keyEquivalent: "p"))
        } else if coordinator.isPaused {
            // Show Resume when paused
            menu.addItem(NSMenuItem(title: "Resume Backup", action: #selector(resumeBackup), keyEquivalent: "r"))
        } else {
            // Show Start when idle
            menu.addItem(NSMenuItem(title: "Start Backup", action: #selector(startBackup), keyEquivalent: "s"))
        }

        menu.addItem(NSMenuItem.separator())

        // Show current status info
        let progress = coordinator.currentProgress
        if progress.totalItems > 0 {
            let statusItem = NSMenuItem(
                title: "\(progress.completedItems) of \(progress.totalItems) backed up (\(progress.percentComplete)%)",
                action: nil,
                keyEquivalent: ""
            )
            statusItem.isEnabled = false
            menu.addItem(statusItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Settings
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit CloudToDisk", action: #selector(quitApp), keyEquivalent: "q"))

        // Set targets for menu items
        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    @objc private func menuBarButtonClicked() {
        // Menu will show automatically
    }

    @objc private func openStatus() {
        showStatusWindow()
    }

    @objc private func startBackup() {
        BackupCoordinator.shared.startBackup()
        updateMenu()
    }

    @objc private func pauseBackup() {
        BackupCoordinator.shared.pauseBackup()
        updateMenu()
    }

    @objc private func resumeBackup() {
        BackupCoordinator.shared.resumeBackup()
        updateMenu()
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
            window.setContentSize(NSSize(width: 500, height: 540))
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
        window.setContentSize(NSSize(width: 500, height: 620))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateState(_ state: BackupState) {
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplay(
                progress: BackupCoordinator.shared.currentProgress,
                isRunning: BackupCoordinator.shared.isRunning
            )
        }
    }
}

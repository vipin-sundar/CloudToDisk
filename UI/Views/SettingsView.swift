//
//  SettingsView.swift
//  CloudToDisk
//
//  Settings and configuration view
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @StateObject private var stateManager = BackupStateManager.shared
    @StateObject private var permissionService = PermissionService.shared
    @State private var destinationPath: String = ""
    @State private var showingFolderPicker = false
    @State private var showingResetConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Destination Section
                    destinationSection

                    // Permissions Section
                    permissionsSection

                    // Advanced Section
                    advancedSection

                    // About Section
                    aboutSection

                    Spacer(minLength: 20)
                }
                .padding(24)
            }

            // Footer
            Divider()
            footerSection
        }
        .frame(width: 500, height: 620)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadSettings()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "0066FF"))

            Text("Settings")
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Destination Section

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(Color(hex: "0066FF"))
                    .font(.system(size: 14, weight: .medium))
                Text("Backup Destination")
                    .font(.system(size: 15, weight: .semibold))
            }

            // Destination Card
            VStack(spacing: 16) {
                if destinationPath.isEmpty {
                    // Empty State
                    VStack(spacing: 14) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(.secondary)

                        Text("No destination selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Choose a folder on your external drive to store your photo backups")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                } else {
                    // Selected Path
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "34C759").opacity(0.12))
                                .frame(width: 40, height: 40)

                            Image(systemName: "externaldrive.fill.badge.checkmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(hex: "34C759"))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Destination")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(destinationPath)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(Color(hex: "34C759").opacity(0.06))
                    .cornerRadius(6)
                }

                // Choose Folder Button
                Button(action: { selectFolder() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        Text(destinationPath.isEmpty ? "Choose Destination Folder" : "Change Destination")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "0066FF"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(Color(hex: "0066FF"))
                    .font(.system(size: 14, weight: .medium))
                Text("Permissions")
                    .font(.system(size: 15, weight: .semibold))
            }

            // Permission Card
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(permissionService.isAuthorized ? Color(hex: "34C759").opacity(0.12) : Color(hex: "FF9500").opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: permissionService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(permissionService.isAuthorized ? Color(hex: "34C759") : Color(hex: "FF9500"))
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photos Library Access")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(spacing: 6) {
                            Circle()
                                .fill(permissionService.isAuthorized ? Color(hex: "34C759") : Color(hex: "FF9500"))
                                .frame(width: 6, height: 6)

                            Text(permissionStatusText)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Action Button
                    if !permissionService.isAuthorized {
                        Button(action: {
                            permissionService.openSystemSettings()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Open Settings")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "FF9500"))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)

                // Help Text
                if !permissionService.isAuthorized {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()

                        Text("CloudToDisk needs access to your Photos library to backup your iCloud photos. Please grant permission in System Settings > Privacy & Security > Photos.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(16)
                            .background(Color(hex: "FF9500").opacity(0.04))
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - About Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .foregroundColor(Color(hex: "FF9500"))
                    .font(.system(size: 14, weight: .medium))
                Text("Advanced")
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(spacing: 12) {
                // Reset Backup History Button
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(Color(hex: "FF3B30"))
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Backup History")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Text("Remove all backup records and start fresh")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Info text
                Text("⚠️ This will clear all backup records. The app will re-backup all photos on the next run. Your backed-up files on the external drive will NOT be deleted.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
            .padding(16)
            .background(Color(hex: "FF3B30").opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "FF3B30").opacity(0.2), lineWidth: 1)
            )
        }
        .alert("Clear Backup History?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear History", role: .destructive) {
                resetBackupHistory()
            }
        } message: {
            Text("This will remove all backup records from the database. You'll be able to re-backup all photos from scratch.\n\nYour files on the external drive will NOT be deleted.")
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: "0066FF"))
                    .font(.system(size: 14, weight: .medium))
                Text("About CloudToDisk")
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(spacing: 16) {
                // Description
                Text("CloudToDisk automatically backs up your iCloud Photos to external storage with intelligent organization and duplicate detection.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                // Features
                VStack(spacing: 14) {
                    FeatureRow(icon: "calendar", title: "Date-Based Organization", description: "Photos organized in YYYY/MM folders")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Resumable Backups", description: "Continues where it left off if interrupted")
                    FeatureRow(icon: "doc.on.doc", title: "Duplicate Detection", description: "Never backs up the same photo twice")
                    FeatureRow(icon: "livephoto", title: "Live Photos Support", description: "Preserves both image and video components")
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            // Version
            Text("Version 1.0")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            // Made with love
            HStack(spacing: 4) {
                Text("Made with")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                Text("for macOS")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Helpers

    private var permissionStatusText: String {
        switch permissionService.authorizationStatus {
        case .authorized:
            return "Access Granted"
        case .denied, .restricted:
            return "Access Denied - Action Required"
        case .notDetermined:
            return "Not Requested"
        case .limited:
            return "Limited Access"
        @unknown default:
            return "Unknown Status"
        }
    }

    private func loadSettings() {
        let config = stateManager.getOrCreateConfiguration()
        destinationPath = config.destinationPath ?? ""
    }

    private func resetBackupHistory() {
        stateManager.resetBackupHistory()

        // Show success feedback
        print("✅ Backup history cleared successfully")

        // Optionally reload settings
        loadSettings()
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select the destination folder for your photo backups"
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK {
            if let url = panel.url {
                destinationPath = url.path
                stateManager.updateConfiguration(destinationPath: destinationPath)
            }
        }
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0066FF"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}

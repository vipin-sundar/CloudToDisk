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
        .frame(width: 560, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadSettings()
        }
    }

    //  Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.blue)

            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    //  Destination Section

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(.blue)
                Text("Backup Destination")
                    .font(.headline)
            }

            // Destination Card
            VStack(spacing: 16) {
                if destinationPath.isEmpty {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No destination selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Choose a folder on your external drive to store your photo backups")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    // Selected Path
                    HStack(spacing: 12) {
                        Image(systemName: "externaldrive.fill.badge.checkmark")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Destination")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(destinationPath)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                }

                // Choose Folder Button
                Button(action: { selectFolder() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text(destinationPath.isEmpty ? "Choose Destination Folder" : "Change Destination")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    //  Permissions Section

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                Text("Permissions")
                    .font(.headline)
            }

            // Permission Card
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(permissionService.isAuthorized ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: permissionService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(permissionService.isAuthorized ? .green : .orange)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photos Library Access")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(permissionService.isAuthorized ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)

                            Text(permissionStatusText)
                                .font(.caption)
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
                                Text("Open Settings")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // Help Text
                if !permissionService.isAuthorized {
                    Text("CloudToDisk needs access to your Photos library to backup your iCloud photos. Please grant permission in System Settings > Privacy & Security > Photos.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.orange.opacity(0.05))
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    //  About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("About CloudToDisk")
                    .font(.headline)
            }

            VStack(spacing: 16) {
                // Description
                Text("CloudToDisk automatically backs up your iCloud Photos to external storage with intelligent organization and duplicate detection.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                // Features
                VStack(spacing: 12) {
                    FeatureRow(icon: "calendar", title: "Date-Based Organization", description: "Photos organized in YYYY/MM folders")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Resumable Backups", description: "Continues where it left off if interrupted")
                    FeatureRow(icon: "doc.on.doc", title: "Duplicate Detection", description: "Never backs up the same photo twice")
                    FeatureRow(icon: "livephoto", title: "Live Photos Support", description: "Preserves both image and video components")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    //  Footer

    private var footerSection: some View {
        HStack {
            // Version
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Made with love
            HStack(spacing: 4) {
                Text("Made with")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text("for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    //  Helpers

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

//  Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}

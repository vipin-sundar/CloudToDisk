//
//  StatusView.swift
//  CloudToDisk
//
//  Main status window showing backup progress
//

import SwiftUI

struct StatusView: View {
    @StateObject private var coordinator = BackupCoordinator.shared
    @StateObject private var permissionService = PermissionService.shared
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection

            Divider()

            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    if !permissionService.isAuthorized {
                        PermissionView()
                            .padding()
                    } else {
                        // Stats Cards
                        statsCardsSection
                            .padding(.horizontal)
                            .padding(.top, 20)

                        // Progress Section
                        if coordinator.isRunning || coordinator.currentProgress.completedItems > 0 {
                            progressSection
                                .padding(.horizontal)
                        }

                        // Error Message
                        if let error = coordinator.errorMessage {
                            errorSection(error)
                                .padding(.horizontal)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }

            // Bottom Action Bar
            if permissionService.isAuthorized {
                Divider()
                actionBar
            }
        }
        .frame(width: 480, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    //  Header Section

    private var headerSection: some View {
        HStack(spacing: 15) {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "cloud")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CloudToDisk")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("iCloud Photos Backup")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status Badge
            statusBadge
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var statusBadge: some View {
        Group {
            if coordinator.isRunning {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                    Text("Running")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(12)
            } else if coordinator.isPaused {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .font(.caption)
                    Text("Paused")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .cornerRadius(12)
            } else if coordinator.currentProgress.isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Complete")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(12)
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                    Text("Idle")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .foregroundColor(.secondary)
                .cornerRadius(12)
            }
        }
    }

    //  Stats Cards Section

    private var statsCardsSection: some View {
        HStack(spacing: 15) {
            // Total Photos Card
            StatCard(
                title: "Total Photos",
                value: "\(coordinator.currentProgress.totalItems)",
                icon: "photo.stack",
                color: .blue
            )

            // Backed Up Card
            StatCard(
                title: "Backed Up",
                value: "\(coordinator.currentProgress.completedItems)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            // Remaining Card
            StatCard(
                title: "Remaining",
                value: "\(coordinator.currentProgress.remainingItems)",
                icon: "clock",
                color: .orange
            )
        }
    }

    //  Progress Section

    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress Header
            HStack {
                Text("Backup Progress")
                    .font(.headline)
                Spacer()
                Text("\(coordinator.currentProgress.percentComplete)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * coordinator.currentProgress.overallProgress,
                            height: 12
                        )
                        .animation(.easeInOut, value: coordinator.currentProgress.overallProgress)
                }
            }
            .frame(height: 12)

            // Current File
            if !coordinator.currentFile.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text(coordinator.currentFile)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(10)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }

            // Stats Row
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(coordinator.currentProgress.completedItems) completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if coordinator.currentProgress.errorCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(coordinator.currentProgress.errorCount) errors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    //  Error Section

    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    //  Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Settings Button
            Button(action: { showSettings = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            // Primary Action Button
            Group {
                if coordinator.isRunning {
                    Button(action: { coordinator.pauseBackup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.large)
                } else if coordinator.isPaused {
                    Button(action: { coordinator.resumeBackup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
                } else {
                    Button(action: { coordinator.startBackup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Start Backup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

//  Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

#Preview {
    StatusView()
}

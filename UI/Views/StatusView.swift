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

            // Main Content (No Scroll)
            VStack(spacing: 16) {
                if !permissionService.isAuthorized {
                    PermissionView()
                        .padding()
                } else {
                    // Stats Cards
                    statsCardsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Progress Section
                    if coordinator.isRunning || coordinator.currentProgress.completedItems > 0 {
                        progressSection
                            .padding(.horizontal, 20)
                    }

                    // Error Message
                    if let error = coordinator.errorMessage {
                        errorSection(error)
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 0)
                }
            }

            // Bottom Action Bar
            if permissionService.isAuthorized {
                Divider()
                actionBar
            }
        }
        .frame(width: 500, height: 540)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0066FF"), Color(hex: "00A3FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "cloud")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("CloudToDisk")
                    .font(.system(size: 20, weight: .semibold))

                Text("iCloud Photos Backup")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status Badge
            statusBadge
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var statusBadge: some View {
        Group {
            if coordinator.isRunning {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 14, height: 14)
                    Text("Running")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "0066FF").opacity(0.12))
                .foregroundColor(Color(hex: "0066FF"))
                .cornerRadius(6)
            } else if coordinator.isPaused {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "FF9500"))
                        .frame(width: 6, height: 6)
                    Text("Paused")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "FF9500").opacity(0.12))
                .foregroundColor(Color(hex: "FF9500"))
                .cornerRadius(6)
            } else if coordinator.currentProgress.isComplete {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "34C759"))
                        .frame(width: 6, height: 6)
                    Text("Complete")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "34C759").opacity(0.12))
                .foregroundColor(Color(hex: "34C759"))
                .cornerRadius(6)
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                    Text("Idle")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.08))
                .foregroundColor(.secondary)
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Stats Cards Section

    private var statsCardsSection: some View {
        HStack(spacing: 10) {
            // Total Photos Card
            StatCard(
                title: "Total Photos",
                value: "\(coordinator.currentProgress.totalItems)",
                icon: "photo.stack",
                color: Color(hex: "0066FF")
            )

            // Backed Up Card
            StatCard(
                title: "Backed Up",
                value: "\(coordinator.currentProgress.completedItems)",
                icon: "checkmark.circle",
                color: Color(hex: "34C759")
            )

            // Remaining Card
            StatCard(
                title: "Remaining",
                value: "\(coordinator.currentProgress.remainingItems)",
                icon: "clock",
                color: Color(hex: "FF9500")
            )
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 10) {
            // Progress Header Card
            HStack {
                Text("Backup Progress")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(coordinator.currentProgress.percentComplete)%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "0066FF"))
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Progress Bar Card
            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 6)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "0066FF"))
                            .frame(
                                width: geometry.size.width * coordinator.currentProgress.overallProgress,
                                height: 6
                            )
                            .animation(.easeInOut(duration: 0.3), value: coordinator.currentProgress.overallProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Current File Card
            if !coordinator.currentFile.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Color(hex: "0066FF"))
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Current File")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(coordinator.currentFile)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }

            // Stats Card
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "34C759"))
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(coordinator.currentProgress.completedItems)")
                            .font(.system(size: 16, weight: .bold))
                        Text("completed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                if coordinator.currentProgress.errorCount > 0 {
                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "FF9500"))
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(coordinator.currentProgress.errorCount)")
                                .font(.system(size: 16, weight: .bold))
                            Text("errors")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Error Section

    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "FF9500"))
                .font(.system(size: 16))

            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "FF9500").opacity(0.08))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "FF9500").opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 10) {
            // Settings Button
            Button(action: { showSettings = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                    Text("Settings")
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Primary Action Button
            Group {
                if coordinator.isRunning {
                    Button(action: { coordinator.pauseBackup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Pause")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "FF9500"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else if coordinator.isPaused {
                    Button(action: { coordinator.resumeBackup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Resume")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "0066FF"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { coordinator.startBackup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Start Backup")
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 32)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            // Icon
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                Spacer()
            }
            .padding(.bottom, 12)

            // Value and Title
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    StatusView()
}

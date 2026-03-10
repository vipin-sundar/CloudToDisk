//
//  PermissionView.swift
//  CloudToDisk
//
//  View for requesting Photos permission
//

import SwiftUI

struct PermissionView: View {
    @StateObject private var permissionService = PermissionService.shared
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0066FF").opacity(0.15), Color(hex: "00A3FF").opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundColor(Color(hex: "0066FF"))
            }

            // Title
            VStack(spacing: 8) {
                Text("Photos Access Required")
                    .font(.system(size: 20, weight: .bold))

                Text("Let's get started by granting access")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // Description
            VStack(spacing: 12) {
                PermissionFeature(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "Your photos never leave your Mac. All backups are local."
                )

                PermissionFeature(
                    icon: "eye.slash.fill",
                    title: "Read-Only Access",
                    description: "CloudToDisk only reads your photos, never modifies them."
                )

                PermissionFeature(
                    icon: "icloud.and.arrow.down",
                    title: "iCloud Photos Support",
                    description: "Automatically downloads photos from iCloud as needed."
                )
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Action Button
            if permissionService.authorizationStatus == .notDetermined {
                Button(action: {
                    requestPermission()
                }) {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text(isRequesting ? "Requesting..." : "Grant Photos Access")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "0066FF"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isRequesting)
                .opacity(isRequesting ? 0.7 : 1.0)
            } else if permissionService.authorizationStatus == .denied || permissionService.authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "FF9500"))
                            .font(.system(size: 14, weight: .medium))
                        Text("Access was denied")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "FF9500").opacity(0.08))
                    .cornerRadius(6)

                    Button(action: {
                        permissionService.openSystemSettings()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Open System Settings")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "FF9500"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Text("Go to System Settings > Privacy & Security > Photos and enable CloudToDisk")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            _ = await permissionService.requestAuthorization()

            await MainActor.run {
                isRequesting = false
            }
        }
    }
}

// MARK: - Permission Feature Component

struct PermissionFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0066FF"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

#Preview {
    PermissionView()
}

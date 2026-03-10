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
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
            }

            // Title
            VStack(spacing: 8) {
                Text("Photos Access Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Let's get started by granting access")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Description
            VStack(spacing: 16) {
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
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

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
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isRequesting ? "Requesting..." : "Grant Photos Access")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
                .disabled(isRequesting)
            } else if permissionService.authorizationStatus == .denied || permissionService.authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Access was denied")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                    Button(action: {
                        permissionService.openSystemSettings()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                            Text("Open System Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)

                    Text("Go to System Settings > Privacy & Security > Photos and enable CloudToDisk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .frame(maxWidth: 400)
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

//  Permission Feature Component

struct PermissionFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
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

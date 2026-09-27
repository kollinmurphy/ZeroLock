//
//  HelpView.swift
//  Broke
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header section
                    headerSection

                    // Hardware requirement callout box
                    hardwareRequirementSection

                    // How it works section
                    howItWorksSection

                    // Why NFC section
                    whyNfcSection

                    // Open Source section
                    openSourceSection
                }
                .padding()
            }
            .navigationTitle("About \(AppConstants.appName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image("GreenIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.appName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Physical App Blocker")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var hardwareRequirementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)

                Text("NFC Tag Required")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text("In order for this app to function, you need a programmable NFC chip.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("\(AppConstants.appName) requires a physical NDEF-compliant NFC tag (such as NTAG213, NTAG215, or NTAG216 stickers, cards, or key fobs). You will program this tag inside the app to toggle app blocking on and off.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.title3)
                .fontWeight(.bold)

            helpStepRow(
                number: "1",
                icon: "square.grid.2x2.fill",
                iconColor: .purple,
                title: "Create App Profiles",
                description: "Set up profiles selecting the specific apps and app categories you want to restrict during focus time."
            )

            helpStepRow(
                number: "2",
                icon: "plus.viewfinder",
                iconColor: .blue,
                title: "Program Your NFC Tag",
                description: "Tap the '+' button in the top-right corner of the main screen and hold your iPhone near your programmable NFC tag to write the \(AppConstants.appName) key."
            )

            helpStepRow(
                number: "3",
                icon: "lock.shield.fill",
                iconColor: .green,
                title: "Lock & Unlock",
                description: "Tap the main center button on the home screen and scan your programmed NFC tag against your iPhone to toggle app blocking."
            )
        }
    }

    private var whyNfcSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .foregroundColor(.blue)

                Text("Why Physical NFC?")
                    .font(.headline)
            }

            Text("Placing your NFC tag across the room or on your desk requires physical movement to unblock distracting apps, breaking digital habits and keeping you focused.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var openSourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "globe.fill")
                    .foregroundColor(.blue)

                Text("Open Source")
                    .font(.headline)
            }

            Text("\(AppConstants.appName) is free and open-source software. It is a fork of the Broke app created by Oz Tamir.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Link(destination: URL(string: "https://github.com/kollinmurphy/broke")!) {
                    HStack {
                        Image(systemName: "safari")
                        Text("App Repository (GitHub)")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }

                Divider()

                Link(destination: URL(string: "https://github.com/OzTamir/broke")!) {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                        Text("Original Repository by Oz Tamir")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private func helpStepRow(number: String, icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

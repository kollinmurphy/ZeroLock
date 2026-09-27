//
//  OnboardingView.swift
//  Broke
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)

                    hardwarePage
                        .tag(1)

                    setupStepsPage
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .tint(colorScheme == .light ? .black : .white)
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = colorScheme == .light ? .black : .white
                }

                bottomNavigationArea
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VerticallyCenteredScrollView {
            VStack(spacing: 24) {
                Image("GreenIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)

                VStack(spacing: 8) {
                    Text("Welcome to \(AppConstants.appName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Physical App Blocker")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Text("ZeroLock uses physical NFC tags to force physical movement whenever you want to lock or unlock distracting apps.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }

    private var hardwarePage: some View {
        VerticallyCenteredScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "sensor.tag.radiowaves.forward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.orange)
                }

                VStack(spacing: 8) {
                    Text("NFC Tag Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("In order for \(AppConstants.appName) to function, you need a programmable NFC chip.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("ZeroLock requires a physical NDEF-compliant NFC tag (such as NTAG213, NTAG215, or NTAG216 stickers, cards, or key fobs).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("You can program your NFC tag inside the app using the '+' button at any time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal)

                // 3D Printer STL & Amazon purchase options
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cube.fill")
                            .foregroundColor(.blue)
                        Text("Getting an NFC Chip & Housing")
                            .font(.headline)
                    }

                    Text("We recommend 3D printing a custom tag case to house your NFC chip, or purchasing a pre-housed NFC key fob or card.")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        Link(destination: URL(string: "https://github.com/kollinmurphy/ZeroLock/blob/main/broke-tag-v2.stl")!) {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Download 3D Printer File (.STL)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }

                        Link(destination: URL(string: "https://www.amazon.com/s?k=nfc+chips+programmable")!) {
                            HStack {
                                Image(systemName: "cart.fill")
                                Text("Buy NFC Tags on Amazon")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }

    private var setupStepsPage: some View {
        VerticallyCenteredScrollView {
            VStack(spacing: 20) {
                Text("How To Set Up")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 20) {
                    stepRow(
                        number: "1",
                        icon: "square.grid.2x2.fill",
                        iconColor: .purple,
                        title: "1. Create App Profiles",
                        description: "Select the apps and categories you wish to block during focus sessions."
                    )

                    stepRow(
                        number: "2",
                        icon: "plus.viewfinder",
                        iconColor: .blue,
                        title: "2. Program NFC Tag",
                        description: "Tap '+' on top right and hold your phone to your NFC chip to write the key."
                    )

                    stepRow(
                        number: "3",
                        icon: "lock.shield.fill",
                        iconColor: .green,
                        title: "3. Lock & Unlock",
                        description: "Tap the main shield button and scan your NFC tag to switch blocking on or off."
                    )

                    // Safari Website Blocking Tip Callout
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Website Blocking Tip")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Only Safari supports blocking individual websites. Chrome and other third-party browsers do not.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }

    // MARK: - Bottom Controls

    private var bottomNavigationArea: some View {
        HStack {
            if currentPage < totalPages - 1 {
                Button(action: {
                    withAnimation {
                        currentPage += 1
                    }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            } else {
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func stepRow(number: String, icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
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

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Helper Views

private struct VerticallyCenteredScrollView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                content
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .center)
            }
        }
    }
}

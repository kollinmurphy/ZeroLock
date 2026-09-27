//
//  BlockerView.swift
//  Broke
//
//  Created by Oz Tamir on 22/08/2024.
//

import SwiftUI
import CoreNFC
import FamilyControls
import ManagedSettings

struct Tactile3DButtonStyle: ButtonStyle {
    let isBlocking: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .shadow(
                color: (isBlocking ? Color.red : Color.green).opacity(configuration.isPressed ? 0.15 : 0.4),
                radius: configuration.isPressed ? 3 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BlockerView: View {
    @EnvironmentObject private var appBlocker: AppBlocker
    @EnvironmentObject private var profileManager: ProfileManager
    @StateObject private var nfcReader = NFCReader()
    @AppStorage(AppConstants.isDemoModeKey) private var isDemoMode = false
    private let tagPhrase = AppConstants.tagPhrase
    
    @State private var showWrongTagAlert = false
    @State private var showCreateTagAlert = false
    @State private var nfcWriteSuccess = false
    @State private var showHelpSheet = false
    @State private var showOnboardingSheet = false
    @State private var isPulsing = false
    
    private var isBlocking: Bool {
        appBlocker.isBlocking
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic ambient background gradient based on blocking state
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Status Card
                        heroStatusCard
                        
                        // Focus Profiles Selector Section
                        if !isBlocking {
                            ProfilesPicker(profileManager: profileManager)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(AppConstants.appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    helpButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    createTagButton
                }
            }
            .sheet(isPresented: $showHelpSheet) {
                HelpView()
                    .environmentObject(appBlocker)
            }
            .sheet(isPresented: $showOnboardingSheet) {
                OnboardingView(hasCompletedOnboarding: .constant(true))
            }
            .alert(isPresented: $showWrongTagAlert) {
                Alert(
                    title: Text("Not a \(AppConstants.appName) Tag"),
                    message: Text("You can create a new \(AppConstants.appName) tag using the + button in the top toolbar."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Create \(AppConstants.appName) Tag", isPresented: $showCreateTagAlert) {
                Button("Create Tag") { createZeroLockTag() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to program your NFC tag with the \(AppConstants.appName) key?")
            }
            .alert("Tag Creation", isPresented: $nfcWriteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(nfcWriteSuccess ? "\(AppConstants.appName) tag created successfully!" : "Failed to create \(AppConstants.appName) tag. Please try again.")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isBlocking)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            if CommandLine.arguments.contains("-UITest_OpenHelp") {
                showHelpSheet = true
            } else if CommandLine.arguments.contains("-UITest_OpenOnboarding") {
                showOnboardingSheet = true
            }
        }
    }
    
    // Dynamic background gradient depending on blocking state
    private var backgroundColor: some View {
        LinearGradient(
            colors: isBlocking ? [
                Color.red.opacity(0.15),
                Color.indigo.opacity(0.20),
                Color(uiColor: .systemBackground)
            ] : [
                Color.green.opacity(0.12),
                Color.teal.opacity(0.10),
                Color(uiColor: .systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Interactive Hero Card
    private var heroStatusCard: some View {
        VStack(spacing: 22) {
            // Status Tag Header
            HStack(spacing: 8) {
                Circle()
                    .fill(isBlocking ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: (isBlocking ? Color.red : Color.green).opacity(isPulsing ? 0.9 : 0.2), radius: isPulsing ? 6 : 2)
                    .opacity(isPulsing ? 1.0 : 0.4)
                
                Text(isBlocking ? "SHIELD ACTIVE" : "READY TO LOCK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isBlocking ? .red : .green)
                    .tracking(1.2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isBlocking ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
            )
            
            // Hero Action Button with GreenIcon / RedIcon App Icons
            Button(action: {
                scanTag()
            }) {
                VStack(spacing: 16) {
                    ZStack {
                        // Raised Outer 3D Bezel Socket
                        Circle()
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                (isBlocking ? Color.red : Color.green).opacity(0.4),
                                                Color(uiColor: .separator).opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                        
                        
                        // Hero Custom App Icon (RedIcon when blocking, GreenIcon when ready)
                        Image("TransparentIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 106, height: 106)
                            .shadow(color: (isBlocking ? Color.red : Color.green).opacity(isPulsing ? 0.5 : 0.2), radius: isPulsing ? 12 : 4, x: 0, y: 4)
                    }
                    
                    // Explicit Action Pill Button Label
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 13, weight: .bold))
                        
                        Text(isDemoMode
                            ? (isBlocking ? "TAP TO UNLOCK" : "TAP TO LOCK")
                            : (isBlocking ? "TAP TO UNLOCK (NFC)" : "TAP TO SCAN NFC TAG"))
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.6)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isBlocking
                                        ? [Color.red, Color.red.opacity(0.85)]
                                        : [Color.green, Color.green.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: (isBlocking ? Color.red : Color.green).opacity(0.35), radius: 6, x: 0, y: 3)
                    )
                }
            }
            .buttonStyle(Tactile3DButtonStyle(isBlocking: isBlocking))
            
            // Main Text Labels
            VStack(spacing: 6) {
                Text(isBlocking ? "Shield Active" : "Ready to Focus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(isDemoMode
                    ? (isBlocking ? "Tap button to unblock apps" : "Tap button to block apps")
                    : (isBlocking ? "Tap button and scan your NFC tag to unblock apps" : "Tap button and hold your NFC tag to the top back of your iPhone."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Active Profile Summary Pill
            HStack(spacing: 8) {
                Image(systemName: profileManager.currentProfile.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isBlocking ? .red : .green)
                
                Text(profileManager.currentProfile.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(uiColor: .tertiarySystemFill))
            )
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            (isBlocking ? Color.red : Color.green).opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
    
    private func scanTag() {
        if isDemoMode {
            appBlocker.toggleBlocking(for: profileManager.currentProfile)
        } else {
            nfcReader.scan { payload in
                if payload == tagPhrase {
                    NSLog("Toggling block. Tag: \(payload)")
                    appBlocker.toggleBlocking(for: profileManager.currentProfile)
                } else {
                    showWrongTagAlert = true
                    NSLog("Wrong Tag!\nPayload: \(payload)")
                }
            }
        }
    }
    
    private var helpButton: some View {
        Button(action: {
            showHelpSheet = true
        }) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.primary)
        }
    }
    
    private var createTagButton: some View {
        Button(action: {
            showCreateTagAlert = true
        }) {
            Image(systemName: "plus.viewfinder")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isBlocking ? .red : .green)
        }
        .disabled(!NFCNDEFReaderSession.readingAvailable)
    }
    
    private func createZeroLockTag() {
        nfcReader.write(tagPhrase) { success in
            nfcWriteSuccess = !success
            showCreateTagAlert = false
        }
    }
}

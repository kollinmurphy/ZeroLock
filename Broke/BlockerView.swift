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

struct BlockerView: View {
    @EnvironmentObject private var appBlocker: AppBlocker
    @EnvironmentObject private var profileManager: ProfileManager
    @StateObject private var nfcReader = NFCReader()
    private let tagPhrase = AppConstants.tagPhrase
    
    @State private var showWrongTagAlert = false
    @State private var showCreateTagAlert = false
    @State private var nfcWriteSuccess = false
    @State private var showHelpSheet = false
    
    private var isBlocking : Bool {
        get {
            return appBlocker.isBlocking
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        blockOrUnblockButton(geometry: geometry)
                        
                        if !isBlocking {
                            Divider()
                            
                            ProfilesPicker(profileManager: profileManager)
                                .frame(height: geometry.size.height / 2)
                                .transition(.move(edge: .bottom))
                        }
                    }
                    .background(isBlocking ? Color("BlockingBackground") : Color("NonBlockingBackground"))
                }
            }
            .navigationBarItems(leading: helpButton, trailing: createTagButton)
            .sheet(isPresented: $showHelpSheet) {
                HelpView()
            }
            .alert(isPresented: $showWrongTagAlert) {
                Alert(
                    title: Text("Not a \(AppConstants.appName) Tag"),
                    message: Text("You can create a new \(AppConstants.appName) tag using the + button"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Create \(AppConstants.appName) Tag", isPresented: $showCreateTagAlert) {
                Button("Create") { createZeroLockTag() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to create a new \(AppConstants.appName) tag?")
            }
            .alert("Tag Creation", isPresented: $nfcWriteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(nfcWriteSuccess ? "\(AppConstants.appName) tag created successfully!" : "Failed to create \(AppConstants.appName) tag. Please try again.")
            }
        }
        .animation(.spring(), value: isBlocking)
    }
    
    @ViewBuilder
    private func blockOrUnblockButton(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            Text(isBlocking ? "Tap to unblock" : "Tap to block")
                .font(.caption)
                .opacity(0.75)
                .transition(.scale)
            
            Button(action: {
                withAnimation(.spring()) {
                    scanTag()
                }
            }) {
                Image(isBlocking ? "RedIcon" : "GreenIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: geometry.size.height / 3)
            }
            .transition(.scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: isBlocking ? geometry.size.height : geometry.size.height / 2)
        .animation(.spring(), value: isBlocking)
    }
    
    private func scanTag() {
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
    
    private var helpButton: some View {
        Button(action: {
            showHelpSheet = true
        }) {
            Image(systemName: "questionmark.circle")
        }
    }
    
    private var createTagButton: some View {
        Button(action: {
            showCreateTagAlert = true
        }) {
            Image(systemName: "plus.viewfinder")
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

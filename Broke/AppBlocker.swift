//
//  AppBlocker.swift
//  Broke
//
//  Created by Oz Tamir on 22/08/2024.
//
import SwiftUI
import ManagedSettings
import FamilyControls

@MainActor
class AppBlocker: ObservableObject {
    let store = ManagedSettingsStore()
    @Published var isBlocking = false
    @Published var isAuthorized = false
    
    init() {
        loadBlockingState()
        Task {
            await requestAuthorization()
        }
    }
    
    func requestAuthorization() async {
        let args = CommandLine.arguments
        if args.contains(where: { $0.hasPrefix("-UITest_") }) {
            self.isAuthorized = true
            return
        }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.isAuthorized = true
        } catch {
            print("Failed to request authorization: \(error)")
            self.isAuthorized = false
        }
    }
    
    func toggleBlocking(for profile: Profile) {
        guard isAuthorized else {
            print("Not authorized to block apps")
            return
        }
        
        isBlocking.toggle()
        saveBlockingState()
        applyBlockingSettings(for: profile)
    }
    
    func applyBlockingSettings(for profile: Profile) {
        if isBlocking {
            NSLog("Blocking \(profile.appTokens.count) apps, \(profile.categoryTokens.count) categories, \(profile.webDomainTokens.count) domains")
            store.shield.applications = profile.appTokens.isEmpty ? nil : profile.appTokens
            store.shield.applicationCategories = profile.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none : .specific(profile.categoryTokens)
            store.shield.webDomains = profile.webDomainTokens.isEmpty ? nil : profile.webDomainTokens
        } else {
            store.shield.applications = nil
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
            store.shield.webDomains = nil
        }
    }
    
    private func loadBlockingState() {
        let args = CommandLine.arguments
        if args.contains("-UITest_ShieldActive") {
            isBlocking = true
            isAuthorized = true
            return
        } else if args.contains("-UITest_ReadyToLock") {
            isBlocking = false
            isAuthorized = true
            return
        }
        isBlocking = UserDefaults.standard.bool(forKey: "isBlocking")
    }
    
    private func saveBlockingState() {
        UserDefaults.standard.set(isBlocking, forKey: "isBlocking")
    }
}

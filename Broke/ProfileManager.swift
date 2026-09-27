//
//  ProfileManager.swift
//  Broke
//
//  Created by Oz Tamir on 22/08/2024.
//

import Foundation
import FamilyControls
import ManagedSettings

class ProfileManager: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var currentProfileId: UUID?
    
    let icons = [
        // Health & Focus
        "figure.mind.and.body", "leaf", "heart", "bolt.heart", "figure.walk", "figure.run",
        "bed.double", "moon", "sun.max",
        "brain.head.profile", "hourglass", "hourglass.circle",
        
        // Work & Productivity
        "doc", "doc.text", "folder", "calendar", "calendar.badge.clock",
        "briefcase", "chart.bar", "chart.pie",
        "paperclip", "pencil", "pencil.circle", "highlighter",
        "book", "text.book.closed",
        
        // Education
        "graduationcap",
        "books.vertical", "text.redaction",
        "square.and.pencil", "lasso.and.sparkles",
        "ruler", "compass.drawing",
        "function", "x.squareroot",
        "number", "character.book.closed",
        
        // Social & Communication
        "message", "bubble.left", "bubble.right", "phone",
        "envelope", "person.2", "person.crop.circle", "person.3",
        
        // Apps & Devices
        "app", "square.grid.2x2", "square.grid.3x2",
        "rectangle.stack", "desktopcomputer", "laptopcomputer",
        "ipad", "iphone", "applewatch", "tv",
        
        // Entertainment & Games
        "gamecontroller", "headphones", "music.note", "music.note.list",
        "play.circle", "pause.circle", "film", "ticket", "sparkles",
        
        // Internet & Browsing
        "safari", "globe", "network",
        "antenna.radiowaves.left.and.right", "link", "magnifyingglass", "wifi",
        
        // Time & Control
        "clock", "alarm", "stopwatch", "timer",
        "bell", "bell.slash", "hand.raised", "lock", "key",
        
        // Misc
        "gear", "gearshape", "slider.horizontal.3", "switch.2", "power",
        "trash", "star", "flag",
        "checkmark.circle", "xmark.circle"
    ]
    
    init() {
        loadProfiles()
        setupForUITestIfNeeded()
        ensureDefaultProfile()
    }
    
    private func setupForUITestIfNeeded() {
        let args = CommandLine.arguments
        guard args.contains(where: { $0.hasPrefix("-UITest_") }) else { return }
        
        let p1 = Profile(name: "Deep Work", appTokens: [], categoryTokens: [], webDomainTokens: [], icon: "brain.head.profile", mockAppCount: 6, mockCategoryCount: 2)
        let p2 = Profile(name: "Social Detox", appTokens: [], categoryTokens: [], webDomainTokens: [], icon: "bubble.left", mockAppCount: 8, mockCategoryCount: 1)
        let p3 = Profile(name: "Bedtime Rest", appTokens: [], categoryTokens: [], webDomainTokens: [], icon: "moon", mockAppCount: 12, mockCategoryCount: 3)
        let p4 = Profile(name: "Study Session", appTokens: [], categoryTokens: [], webDomainTokens: [], icon: "book", mockAppCount: 4, mockCategoryCount: 1)
        
        profiles = [p1, p2, p3, p4]
        currentProfileId = p1.id
    }
    
    var currentProfile: Profile {
        (profiles.first(where: { $0.id == currentProfileId }) ?? profiles.first(where: { $0.name == "Default" })) ?? profiles.first!
    }
    
    func loadProfiles() {
        if let savedProfiles = UserDefaults.standard.data(forKey: "savedProfiles"),
           let decodedProfiles = try? JSONDecoder().decode([Profile].self, from: savedProfiles) {
            profiles = decodedProfiles
        } else {
            // Create a default profile if no profiles are saved
            let defaultProfile = Profile(name: "Default", appTokens: [], categoryTokens: [], webDomainTokens: [], icon: "bell.slash")
            profiles = [defaultProfile]
            currentProfileId = defaultProfile.id
        }
        
        if let savedProfileId = UserDefaults.standard.string(forKey: "currentProfileId"),
           let uuid = UUID(uuidString: savedProfileId) {
            currentProfileId = uuid
            NSLog("Found currentProfile: \(uuid)")
        } else {
            currentProfileId = profiles.first?.id
            NSLog("No stored ID, using \(currentProfileId?.uuidString ?? "NONE")")
        }
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: "savedProfiles")
        }
        UserDefaults.standard.set(currentProfileId?.uuidString, forKey: "currentProfileId")
    }
    
    func addProfile(name: String, icon: String = "figure.mind.and.body") {
        let newProfile = Profile(name: name, appTokens: [], categoryTokens: [], webDomainTokens: [], icon: icon)
        profiles.append(newProfile)
        currentProfileId = newProfile.id
        saveProfiles()
    }
    
    func addProfile(newProfile: Profile) {
        profiles.append(newProfile)
        currentProfileId = newProfile.id
        saveProfiles()
    }
    
    func setCurrentProfile(id: UUID) {
        if profiles.contains(where: { $0.id == id }) {
            currentProfileId = id
            NSLog("New Current Profile: \(id)")
            saveProfiles()
        }
    }
    
    func moveProfile(from sourceID: UUID, to destinationID: UUID) {
        guard let fromIndex = profiles.firstIndex(where: { $0.id == sourceID }),
              let toIndex = profiles.firstIndex(where: { $0.id == destinationID }),
              fromIndex != toIndex else { return }
        
        let movedProfile = profiles.remove(at: fromIndex)
        profiles.insert(movedProfile, at: toIndex)
        saveProfiles()
    }
    
    func deleteProfile(withId id: UUID) {
        profiles.removeAll { $0.id == id }
        
        if currentProfileId == id {
            currentProfileId = profiles.first?.id
        }
        
        saveProfiles()
    }
    
    func updateProfile(
        id: UUID,
        name: String? = nil,
        appTokens: Set<ApplicationToken>? = nil,
        categoryTokens: Set<ActivityCategoryToken>? = nil,
        webDomainTokens: Set<WebDomainToken>? = nil,
        icon: String? = nil
    ) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            if let name = name {
                profiles[index].name = name
            }
            if let appTokens = appTokens {
                profiles[index].appTokens = appTokens
            }
            if let categoryTokens = categoryTokens {
                profiles[index].categoryTokens = categoryTokens
            }
            if let webDomainTokens = webDomainTokens {
                profiles[index].webDomainTokens = webDomainTokens
            }
            if let icon = icon {
                profiles[index].icon = icon
            }
            
            if currentProfileId == id {
                currentProfileId = profiles[index].id
            }
            
            saveProfiles()
        }
    }
    
    private func ensureDefaultProfile() {
        if profiles.isEmpty {
            let defaultProfile = Profile(name: "Default", appTokens: [], categoryTokens: [], webDomainTokens: [], icon: "bell.slash")
            profiles.append(defaultProfile)
            currentProfileId = defaultProfile.id
            saveProfiles()
        } else if currentProfileId == nil {
            if let defaultProfile = profiles.first(where: { $0.name == "Default" }) {
                currentProfileId = defaultProfile.id
            } else {
                currentProfileId = profiles.first?.id
            }
            saveProfiles()
        }
    }
    
    func getInitialIcon() -> String {
        let usedIcons = Set(profiles.map { $0.icon })
        let availableIcons = icons.filter { !usedIcons.contains($0) }
        return availableIcons.randomElement() ?? "figure.mind.and.body"
    }
}

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var appTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
    var webDomainTokens: Set<WebDomainToken>
    var icon: String
    var mockAppCount: Int?
    var mockCategoryCount: Int?
    
    var appCount: Int {
        mockAppCount ?? appTokens.count
    }
    
    var categoryCount: Int {
        mockCategoryCount ?? categoryTokens.count
    }
    
    var isDefault: Bool {
        name == "Default"
    }
    
    init(
        name: String,
        appTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken>,
        webDomainTokens: Set<WebDomainToken>,
        icon: String = "bell.slash",
        mockAppCount: Int? = nil,
        mockCategoryCount: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.appTokens = appTokens
        self.categoryTokens = categoryTokens
        self.icon = icon
        self.webDomainTokens = webDomainTokens
        self.mockAppCount = mockAppCount
        self.mockCategoryCount = mockCategoryCount
    }
}

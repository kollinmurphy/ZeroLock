//
//  EditProfileView.swift
//  Broke
//
//  Created by Oz Tamir on 23/08/2024.
//

import SwiftUI
import FamilyControls

struct ProfileFormView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var profileName: String
    @State private var profileIcon: String
    @State private var showSymbolsPicker = false
    @State private var showAppSelection = false
    @State private var activitySelection: FamilyActivitySelection
    @State private var showDeleteConfirmation = false
    @FocusState private var isTextFieldFocused: Bool
    let profile: Profile?
    let canDelete: Bool
    let onDismiss: () -> Void
    
    init(profile: Profile? = nil, canDelete: Bool = false, profileManager: ProfileManager, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.canDelete = canDelete
        self.profileManager = profileManager
        self.onDismiss = onDismiss
        _profileName = State(initialValue: profile?.name ?? "")
        _profileIcon = State(initialValue: profile?.icon ?? profileManager.getInitialIcon())
        
        var selection = FamilyActivitySelection()
        selection.applicationTokens = profile?.appTokens ?? []
        selection.categoryTokens = profile?.categoryTokens ?? []
        selection.webDomainTokens = profile?.webDomainTokens ?? []
        _activitySelection = State(initialValue: selection)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Profile Info Card
                        profileInfoCard
                        
                        // 2. Screen Time Restrictions Card (Standard Button + Separate Chips Row)
                        restrictionsCard
                        
                        // 3. Delete Action (if editing existing profile)
                        if profile != nil && canDelete {
                            deleteProfileButton
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(profile == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: handleSave)
                        .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showSymbolsPicker) {
                IconSelectionSheet(icons: profileManager.icons, selectedIcon: $profileIcon)
                    .interactiveDismissDisabled(true)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationStack {
                    FamilyActivityPicker(selection: $activitySelection)
                        .navigationTitle("Select Apps")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showAppSelection = false
                                }
                                .fontWeight(.bold)
                            }
                        }
                }
                .interactiveDismissDisabled(true)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Profile"),
                    message: Text("Are you sure you want to delete this profile?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let profile = profile {
                            profileManager.deleteProfile(withId: profile.id)
                        }
                        onDismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // Profile Name and Icon Card
    private var profileInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROFILE DETAILS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(0.8)
            
            HStack(spacing: 14) {
                // Icon Selector Button
                Button(action: { showSymbolsPicker = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: profileIcon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                            .offset(x: 20, y: 20)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Profile Name TextField
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Name")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g. Deep Work, Sleep, Gym", text: $profileName)
                        .font(.headline)
                        .focused($isTextFieldFocused)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // Screen Time Restrictions Card with Standard Button & Separate Chips Row
    private var restrictionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SCREEN TIME RESTRICTIONS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(0.8)
            
            VStack(alignment: .leading, spacing: 14) {
                // Standard Primary Action Button
                Button(action: { showAppSelection = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "app.badge.checkmark.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Choose Blocked Activities")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Separate Metric Chips Row (shown only if items are selected)
                if hasSelectedActivities {
                    HStack(spacing: 8) {
                        let appCount = activitySelection.applicationTokens.count > 0 ? activitySelection.applicationTokens.count : (profile?.appCount ?? 0)
                        let catCount = activitySelection.categoryTokens.count > 0 ? activitySelection.categoryTokens.count : (profile?.categoryCount ?? 0)
                        
                        if appCount > 0 {
                            metricChip(
                                icon: "app.badge",
                                count: appCount,
                                label: appCount == 1 ? "App" : "Apps",
                                color: .blue
                            )
                        }
                        
                        if catCount > 0 {
                            metricChip(
                                icon: "square.stack.3d.up.fill",
                                count: catCount,
                                label: catCount == 1 ? "Category" : "Categories",
                                color: .purple
                            )
                        }
                        
                        if activitySelection.webDomainTokens.count > 0 {
                            metricChip(
                                icon: "safari",
                                count: activitySelection.webDomainTokens.count,
                                label: activitySelection.webDomainTokens.count == 1 ? "Site" : "Sites",
                                color: .teal
                            )
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private var hasSelectedActivities: Bool {
        (profile?.appCount ?? 0) > 0 ||
        (profile?.categoryCount ?? 0) > 0 ||
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty ||
        !activitySelection.webDomainTokens.isEmpty
    }
    
    // Custom Metric Chip Component
    private func metricChip(icon: String, count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color(uiColor: .tertiarySystemFill))
        )
    }
    
    // Delete Profile Button
    private var deleteProfileButton: some View {
        Button(action: { showDeleteConfirmation = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Delete Profile")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 8)
    }
    
    private func handleSave() {
        let trimmedName = profileName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if let existingProfile = profile {
            profileManager.updateProfile(
                id: existingProfile.id,
                name: trimmedName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                webDomainTokens: activitySelection.webDomainTokens,
                icon: profileIcon
            )
        } else {
            let newProfile = Profile(
                name: trimmedName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                webDomainTokens: activitySelection.webDomainTokens,
                icon: profileIcon
            )
            profileManager.addProfile(newProfile: newProfile)
        }
        onDismiss()
    }
}

struct IconSelectionSheet: View {
    let icons: [String]
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    let columns = [GridItem(.adaptive(minimum: 60), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                selectedIcon = icon
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                dismiss()
                            }
                        }) {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.18) : Color(uiColor: .tertiarySystemFill))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

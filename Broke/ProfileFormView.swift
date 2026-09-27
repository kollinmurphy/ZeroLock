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
    let iconSize: CGFloat = 28
    
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
            Form {
                Section(header: Text("Profile Info")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter profile name", text: $profileName)
                            .focused($isTextFieldFocused)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = true
                    }
                    
                    Button(action: { showSymbolsPicker = true }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: profileIcon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Select Icon")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section(header: Text("Screen Time Restrictions")) {
                    Button(action: { showAppSelection = true }) {
                        HStack {
                            Text("Choose Blocked Activities")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                        Text("Blocked Apps")
                        Spacer()
                        Text("\(activitySelection.applicationTokens.count)")
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundColor(.purple)
                        Text("Blocked Categories")
                        Spacer()
                        Text("\(activitySelection.categoryTokens.count)")
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "safari")
                            .foregroundColor(.teal)
                        Text("Blocked Sites")
                        Spacer()
                        Text("\(activitySelection.webDomainTokens.count)")
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                
                if profile != nil && canDelete {
                    Section {
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Spacer()
                                Text("Delete Profile")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
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
                        .disabled(profileName.isEmpty)
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
    
    private func handleSave() {
        if let existingProfile = profile {
            profileManager.updateProfile(
                id: existingProfile.id,
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                webDomainTokens: activitySelection.webDomainTokens,
                icon: profileIcon
            )
        } else {
            let newProfile = Profile(
                name: profileName,
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

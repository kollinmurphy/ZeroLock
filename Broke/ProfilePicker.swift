//
//  ProfilePicker.swift
//  Broke
//
//  Created by Oz Tamir on 23/08/2024.
//

import SwiftUI
import FamilyControls

struct ProfilesPicker: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var showAddProfileView = false
    @State private var editingProfile: Profile?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(.blue)
                    .font(.headline)
                
                Text("Focus Profiles")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 4)
            
            // Grid of Profile Cards
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(profileManager.profiles) { profile in
                    let isSelected = (profile.id == profileManager.currentProfileId)
                    
                    ProfileCardView(
                        profile: profile,
                        isSelected: isSelected,
                        onSelect: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if isSelected {
                                    editingProfile = profile
                                } else {
                                    profileManager.setCurrentProfile(id: profile.id)
                                }
                            }
                        },
                        onEdit: {
                            editingProfile = profile
                        }
                    )
                }
                
                // Add Profile Card
                AddProfileCardButton {
                    showAddProfileView = true
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
        .sheet(item: $editingProfile) { profile in
            ProfileFormView(
                profile: profile,
                canDelete: profileManager.profiles.count > 1,
                profileManager: profileManager
            ) {
                editingProfile = nil
            }
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showAddProfileView) {
            ProfileFormView(profileManager: profileManager) {
                showAddProfileView = false
            }
            .interactiveDismissDisabled(true)
        }
    }
}

struct ProfileCardView: View {
    let profile: Profile
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Top row: Icon and Options Button
                HStack(alignment: .center) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? Color.blue.opacity(0.18) : Color(uiColor: .tertiarySystemFill))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: profile.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .blue : .primary)
                    }
                    
                    Spacer()
                    
                    Button(action: onEdit) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Profile Name
                Text(profile.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Metric Badges
                HStack(spacing: 6) {
                    badgePill(icon: "app.badge", count: profile.appTokens.count, label: "apps")
                    if !profile.categoryTokens.isEmpty {
                        badgePill(icon: "square.stack.3d.up.fill", count: profile.categoryTokens.count, label: "cats")
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.06) : Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Color.blue : Color(uiColor: .separator).opacity(0.4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.15) : Color.black.opacity(0.02),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onEdit()
        }
    }
    
    private func badgePill(icon: String, count: Int, label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(uiColor: .secondarySystemFill))
        )
    }
}

struct AddProfileCardButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Text("Add Profile")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        Color.blue.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.blue.opacity(0.02))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

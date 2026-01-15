//
//  ProfileViewModel.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let profileKey = "local_profile"
    
    func loadProfile(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        // Load from local storage
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = savedProfile
        } else {
            // Create new profile
            profile = UserProfile(userId: userId, name: nil)
        }
    }
    
    func updateProfile(name: String?, avatarUrl: String?, theme: String?, fontSize: Double?, notificationTime: String?, userId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let updatedProfile = UserProfile(
            id: profile?.id ?? UUID(),
            userId: userId,
            name: name ?? profile?.name,
            avatarUrl: avatarUrl ?? profile?.avatarUrl,
            theme: theme ?? profile?.theme,
            fontSize: fontSize ?? profile?.fontSize,
            notificationTime: notificationTime ?? profile?.notificationTime,
            createdAt: profile?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        // Save to local storage
        if let data = try? JSONEncoder().encode(updatedProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
            UserDefaults.standard.synchronize()
        }
        
        profile = updatedProfile
        return true
    }
}

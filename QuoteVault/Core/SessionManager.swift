//
//  SessionManager.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import Supabase

@MainActor
final class SessionManager: ObservableObject {
    @Published var session: Session?
    @Published var isLoading: Bool = true
    
    private let hasLaunchedKey = "hasLaunchedBefore"

    init() {
        Task {
            await loadSession()
        }
    }
    
    func loadSession() async {
        isLoading = true
        
        // Small delay to show splash screen
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        defer { isLoading = false }
        
        // Check if this is a fresh install
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedKey)
        
        if !hasLaunchedBefore {
            // Fresh install - clear any old session and show login
            print("Fresh install detected - showing login screen")
            try? await SupabaseManager.shared.client.auth.signOut()
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
            UserDefaults.standard.synchronize()
            self.session = nil
            return
        }
        
        do {
            // Try to get current session from Supabase
            let fetched = try await SupabaseManager.shared.client.auth.session
            
            // Check if session is valid and not expired
            if fetched.isExpired {
                print("Session expired, clearing...")
                self.session = nil
            } else {
                print("Valid session found for: \(fetched.user.email ?? "unknown")")
                self.session = fetched
            }
        } catch {
            // No valid session exists - user needs to login
            print("No valid session found: \(error.localizedDescription)")
            self.session = nil
        }
    }
    
    func setSession(_ session: Session) {
        self.session = session
    }

    func signOut() async {
        try? await SupabaseManager.shared.client.auth.signOut()
        session = nil
        // Clear any cached data
        UserDefaults.standard.removeObject(forKey: "local_favorites")
        UserDefaults.standard.removeObject(forKey: "local_profile")
        // Keep hasLaunchedBefore so next login works
    }
}


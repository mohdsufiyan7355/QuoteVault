//
//  SupabaseManager.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Supabase
import Foundation

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let supabaseURL = URL(string: "https://ldadpnqckarxiapalais.supabase.co") else {
            fatalError("Invalid Supabase URL")
        }
        
        let supabaseKey = "sb_publishable_TERw6bbFn1jjXrNsMooOaQ_lG8EHIlM"

        // Opt-in to the new initial-session emission behavior to avoid the warning from supabase-swift.
        // When enabled, the locally stored session may be emitted even if expired, so call-sites
        // that rely on "session != nil" should also check `session.isExpired`.
        let options = SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: options
        )
    }
}


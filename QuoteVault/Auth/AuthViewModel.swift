//
//  AuthViewModel.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func login() async -> Session? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Retry logic for network issues
            var lastError: Error?
            for attempt in 1...3 {
                do {
                    let session = try await SupabaseManager.shared.client.auth.signIn(
                        email: email,
                        password: password
                    )
                    return session
                } catch {
                    lastError = error
                    // If it's a network error and we have retries left, wait and retry
                    if attempt < 3, let urlError = error as? URLError,
                       urlError.code == .networkConnectionLost || urlError.code == .timedOut {
                        try? await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000)) // Wait 1s, 2s
                        continue
                    }
                    throw error
                }
            }
            throw lastError ?? NSError(domain: "AuthError", code: -1)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNetworkConnectionLost:
                    errorMessage = "Network connection lost. Please check your internet connection and try again."
                case NSURLErrorTimedOut:
                    errorMessage = "Request timed out. Please try again."
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "No internet connection. Please check your network settings."
                default:
                    errorMessage = "Network error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            print("Login error: \(error)")
            return nil
        }
    }

    func signUp() async -> Session? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Retry logic for network issues
            var lastError: Error?
            for attempt in 1...3 {
                do {
                    let response = try await SupabaseManager.shared.client.auth.signUp(
                        email: email,
                        password: password
                    )
                    return response.session
                } catch {
                    lastError = error
                    // If it's a network error and we have retries left, wait and retry
                    if attempt < 3, let urlError = error as? URLError,
                       urlError.code == .networkConnectionLost || urlError.code == .timedOut {
                        try? await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000)) // Wait 1s, 2s
                        continue
                    }
                    throw error
                }
            }
            throw lastError ?? NSError(domain: "AuthError", code: -1)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNetworkConnectionLost:
                    errorMessage = "Network connection lost. Please check your internet connection and try again."
                case NSURLErrorTimedOut:
                    errorMessage = "Request timed out. Please try again."
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "No internet connection. Please check your network settings."
                default:
                    errorMessage = "Network error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            print("Signup error: \(error)")
            return nil
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await SupabaseManager.shared.client.auth.resetPasswordForEmail(email)
            errorMessage = nil // Success
        } catch {
            errorMessage = error.localizedDescription
            print("Password reset error: \(error)")
        }
    }
}


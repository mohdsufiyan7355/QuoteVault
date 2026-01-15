//
//  FavoriteViewModel.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import Supabase

@MainActor
class FavoriteViewModel: ObservableObject {
    static let shared = FavoriteViewModel()
    
    @Published var favoriteQuotes: [Quote] = []
    @Published var favoriteQuoteIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let favoritesKey = "local_favorites"
    
    init() {
        loadLocalFavorites()
    }
    
    // MARK: - Local Storage
    private func loadLocalFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let ids = try? JSONDecoder().decode([UUID].self, from: data) {
            favoriteQuoteIds = Set(ids)
            updateFavoriteQuotes()
        }
    }
    
    private func saveLocalFavorites() {
        if let data = try? JSONEncoder().encode(Array(favoriteQuoteIds)) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func updateFavoriteQuotes() {
        favoriteQuotes = QuoteViewModel.localQuotes.filter { favoriteQuoteIds.contains($0.id) }
    }
    
    // MARK: - Public Methods
    func loadFavorites(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        // Always load from local first
        loadLocalFavorites()
        
        // Try Supabase sync
        do {
            let favorites: [Favorite] = try await SupabaseManager.shared.client
                .from(AppConstants.Strings.favoritesTable)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            if !favorites.isEmpty {
                let quoteIds = favorites.map { $0.quoteId.uuidString }
                let quotes: [Quote] = try await SupabaseManager.shared.client
                    .from(AppConstants.Strings.quotesTable)
                    .select()
                    .in("id", values: quoteIds)
                    .execute()
                    .value
                
                let quoteDict = Dictionary(uniqueKeysWithValues: quotes.map { ($0.id, $0) })
                favoriteQuotes = favorites.compactMap { quoteDict[$0.quoteId] }
                favoriteQuoteIds = Set(favoriteQuotes.map { $0.id })
                saveLocalFavorites()
            }
        } catch {
            print("Supabase error, using local favorites: \(error)")
        }
    }
    
    func toggleFavorite(quoteId: UUID, userId: UUID) async -> Bool {
        let isCurrentlyFavorite = favoriteQuoteIds.contains(quoteId)
        
        if isCurrentlyFavorite {
            // Remove from favorites
            favoriteQuoteIds.remove(quoteId)
            favoriteQuotes.removeAll { $0.id == quoteId }
        } else {
            // Add to favorites
            favoriteQuoteIds.insert(quoteId)
            if let quote = QuoteViewModel.localQuotes.first(where: { $0.id == quoteId }) {
                favoriteQuotes.insert(quote, at: 0)
            }
        }
        
        // Save locally immediately
        saveLocalFavorites()
        
        // Notify all observers
        objectWillChange.send()
        
        // Try to sync with Supabase (non-blocking)
        Task.detached { [weak self] in
            await self?.syncFavoriteToCloud(quoteId: quoteId, userId: userId, add: !isCurrentlyFavorite)
        }
        
        return !isCurrentlyFavorite
    }
    
    private func syncFavoriteToCloud(quoteId: UUID, userId: UUID, add: Bool) async {
        do {
            if add {
                let newFavorite = Favorite(
                    id: UUID(),
                    userId: userId,
                    quoteId: quoteId,
                    createdAt: Date()
                )
                try await SupabaseManager.shared.client
                    .from(AppConstants.Strings.favoritesTable)
                    .insert(newFavorite)
                    .execute()
            } else {
                try await SupabaseManager.shared.client
                    .from(AppConstants.Strings.favoritesTable)
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("quote_id", value: quoteId.uuidString)
                    .execute()
            }
        } catch {
            print("Cloud sync error (ignored): \(error)")
        }
    }
    
    func isFavorite(quoteId: UUID, userId: UUID) async -> Bool {
        return favoriteQuoteIds.contains(quoteId)
    }
    
    func isFavoriteSync(quoteId: UUID) -> Bool {
        return favoriteQuoteIds.contains(quoteId)
    }
}

//
//  CollectionViewModel.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import Supabase

@MainActor
class CollectionViewModel: ObservableObject {
    @Published var collections: [Collection] = []
    @Published var collectionQuotes: [UUID: [Quote]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadCollections(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            collections = try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionsTable)
                .select()
                .eq("userId", value: userId.uuidString)
                .order("createdAt", ascending: false)
                .execute()
                .value
            
            // Load quotes for each collection
            for collection in collections {
                await loadCollectionQuotes(collectionId: collection.id)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading collections: \(error)")
        }
    }
    
    func loadCollectionQuotes(collectionId: UUID) async {
        do {
            let collectionQuotes: [CollectionQuote] = try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionQuotesTable)
                .select()
                .eq("collectionId", value: collectionId.uuidString)
                .execute()
                .value
            
            guard !collectionQuotes.isEmpty else {
                self.collectionQuotes[collectionId] = []
                return
            }
            
            let quoteIds = collectionQuotes.map { $0.quoteId.uuidString }
            let quotes: [Quote] = try await SupabaseManager.shared.client
                .from(AppConstants.Strings.quotesTable)
                .select()
                .in("id", value: quoteIds)
                .execute()
                .value
            
            self.collectionQuotes[collectionId] = quotes
        } catch {
            print("Error loading collection quotes: \(error)")
        }
    }
    
    func createCollection(name: String, userId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let collection = Collection(
                id: UUID(),
                userId: userId,
                name: name,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionsTable)
                .insert(collection)
                .execute()
            
            await loadCollections(userId: userId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Error creating collection: \(error)")
            return false
        }
    }
    
    func addQuoteToCollection(quoteId: UUID, collectionId: UUID) async -> Bool {
        do {
            let collectionQuote = CollectionQuote(
                id: UUID(),
                collectionId: collectionId,
                quoteId: quoteId,
                addedAt: Date()
            )
            
            try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionQuotesTable)
                .insert(collectionQuote)
                .execute()
            
            await loadCollectionQuotes(collectionId: collectionId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Error adding quote to collection: \(error)")
            return false
        }
    }
    
    func removeQuoteFromCollection(quoteId: UUID, collectionId: UUID) async -> Bool {
        do {
            let existing: [CollectionQuote] = try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionQuotesTable)
                .select()
                .eq("collectionId", value: collectionId.uuidString)
                .eq("quoteId", value: quoteId.uuidString)
                .execute()
                .value
            
            if let collectionQuote = existing.first {
                try await SupabaseManager.shared.client
                    .from(AppConstants.Strings.collectionQuotesTable)
                    .delete()
                    .eq("id", value: collectionQuote.id.uuidString)
                    .execute()
                
                await loadCollectionQuotes(collectionId: collectionId)
                return true
            }
            return false
        } catch {
            errorMessage = error.localizedDescription
            print("Error removing quote from collection: \(error)")
            return false
        }
    }
    
    func deleteCollection(collectionId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Delete collection quotes first
            try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionQuotesTable)
                .delete()
                .eq("collectionId", value: collectionId.uuidString)
                .execute()
            
            // Delete collection
            try await SupabaseManager.shared.client
                .from(AppConstants.Strings.collectionsTable)
                .delete()
                .eq("id", value: collectionId.uuidString)
                .execute()
            
            await loadCollections(userId: userId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting collection: \(error)")
            return false
        }
    }
}

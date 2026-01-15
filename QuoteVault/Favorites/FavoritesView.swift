//
//  FavoritesView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var favoriteVM = FavoriteViewModel.shared
    @StateObject private var collectionVM = CollectionViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedTab) {
                    Text("Favorites").tag(0)
                    Text("Collections").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                Spacer()
                
                if selectedTab == 0 {
                    favoritesList
                } else {
                    collectionsList
                }
                Spacer()
            }
            .navigationTitle("My Library")
            .refreshable {
                await refresh()
            }
            .task {
                await refresh()
            }
        }
    }
    
    private var favoritesList: some View {
        Group {
            if favoriteVM.isLoading && favoriteVM.favoriteQuotes.isEmpty {
                ProgressView()
                    .padding()
            } else if favoriteVM.favoriteQuotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No favorites yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap the heart icon on any quote to add it to favorites")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(favoriteVM.favoriteQuotes) { quote in
                            QuoteCard(
                                quote: quote,
                                userId: sessionManager.session?.user.id ?? UUID(),
                                favoriteVM: favoriteVM
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var collectionsList: some View {
        Group {
            if collectionVM.isLoading && collectionVM.collections.isEmpty {
                ProgressView()
                    .padding()
            } else if collectionVM.collections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No collections yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Create collections to organize your favorite quotes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 40)
            } else {
                List {
                    ForEach(collectionVM.collections) { coll in
                        NavigationLink(destination: CollectionDetailView(collection: coll, userId: sessionManager.session?.user.id ?? UUID())) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(coll.name)
                                        .font(.headline)
                                    if let quotes = collectionVM.collectionQuotes[coll.id] {
                                        Text("\(quotes.count) quotes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let collection = collectionVM.collections[index]
                            Task {
                                _ = await collectionVM.deleteCollection(
                                    collectionId: collection.id,
                                    userId: sessionManager.session?.user.id ?? UUID()
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func refresh() async {
        guard let userId = sessionManager.session?.user.id else { return }
        await favoriteVM.loadFavorites(userId: userId)
        await collectionVM.loadCollections(userId: userId)
    }
}

struct CollectionDetailView: View {
    let collection: QuoteVault.Collection
    let userId: UUID
    @StateObject private var collectionVM = CollectionViewModel()
    @ObservedObject private var favoriteVM = FavoriteViewModel.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let quotes = collectionVM.collectionQuotes[collection.id] {
                    if quotes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No quotes in this collection")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(quotes) { quote in
                            QuoteCard(
                                quote: quote,
                                userId: userId,
                                favoriteVM: favoriteVM
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(collection.name)
        .task {
            await collectionVM.loadCollectionQuotes(collectionId: collection.id)
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}

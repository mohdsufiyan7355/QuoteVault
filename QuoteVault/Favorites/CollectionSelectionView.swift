//
//  CollectionSelectionView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct CollectionSelectionView: View {
    let quoteId: UUID
    let userId: UUID
    @StateObject private var collectionVM = CollectionViewModel()
    @State private var showingNewCollection = false
    @State private var newCollectionName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Add to Collection") {
                    Button(action: { showingNewCollection = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("Create New Collection")
                        }
                    }
                }
                
                Section("Existing Collections") {
                    if collectionVM.isLoading {
                        ProgressView()
                    } else if collectionVM.collections.isEmpty {
                        Text("No collections yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(collectionVM.collections) { collection in
                            CollectionRow(
                                collection: collection,
                                quoteId: quoteId,
                                userId: userId,
                                collectionVM: collectionVM
                            )
                        }
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New Collection", isPresented: $showingNewCollection) {
                TextField("Collection Name", text: $newCollectionName)
                Button("Cancel", role: .cancel) { newCollectionName = "" }
                Button("Create") {
                    Task {
                        if await collectionVM.createCollection(name: newCollectionName, userId: userId) {
                            newCollectionName = ""
                        }
                    }
                }
            } message: {
                Text("Enter a name for your new collection")
            }
            .task {
                await collectionVM.loadCollections(userId: userId)
            }
        }
    }
}

struct CollectionRow: View {
    let collection: Collection
    let quoteId: UUID
    let userId: UUID
    @ObservedObject var collectionVM: CollectionViewModel
    @State private var isInCollection = false
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.accentColor)
            Text(collection.name)
            Spacer()
            if isInCollection {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                if isInCollection {
                    _ = await collectionVM.removeQuoteFromCollection(quoteId: quoteId, collectionId: collection.id)
                } else {
                    _ = await collectionVM.addQuoteToCollection(quoteId: quoteId, collectionId: collection.id)
                }
                isInCollection.toggle()
            }
        }
        .task {
            if let quotes = collectionVM.collectionQuotes[collection.id] {
                isInCollection = quotes.contains { $0.id == quoteId }
            }
        }
    }
}

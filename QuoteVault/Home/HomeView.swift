//
//  HomeView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var quoteVM = QuoteViewModel()
    @ObservedObject private var favoriteVM = FavoriteViewModel.shared
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingSearch = false
    @State private var showingCategoryFilter = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Quote Section
                    if let dailyQuote = quoteVM.dailyQuote {
                        DailyQuoteCard(quote: dailyQuote)
                            .padding(.horizontal)
                    }
                    
                    // Category Filter
                    if !showingSearch {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryChip(title: "All", isSelected: quoteVM.selectedCategory == nil) {
                                    quoteVM.selectedCategory = nil
                                    Task { await quoteVM.loadQuotes(refresh: true) }
                                }
                                
                                ForEach(AppConstants.Categories.all, id: \.self) { category in
                                    CategoryChip(title: category, isSelected: quoteVM.selectedCategory == category) {
                                        quoteVM.selectedCategory = category
                                        Task { await quoteVM.loadQuotes(refresh: true) }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Search Bar
                    if showingSearch {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Search quotes...", text: $quoteVM.searchText)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                                    .onChange(of: quoteVM.searchText) { _ in
                                        Task { await quoteVM.searchQuotes() }
                                    }
                                
                                if !quoteVM.searchText.isEmpty {
                                    Button(action: {
                                        quoteVM.searchText = ""
                                        Task { await quoteVM.loadQuotes(refresh: true) }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)
                                TextField("Search by author...", text: $quoteVM.searchAuthor)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                                    .onChange(of: quoteVM.searchAuthor) { _ in
                                        Task { await quoteVM.searchQuotes() }
                                    }
                                
                                if !quoteVM.searchAuthor.isEmpty {
                                    Button(action: {
                                        quoteVM.searchAuthor = ""
                                        Task { await quoteVM.loadQuotes(refresh: true) }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            // Search Button
                            Button(action: {
                                Task { await quoteVM.searchQuotes() }
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quotes List
                    if quoteVM.isLoading && quoteVM.quotes.isEmpty {
                        ProgressView()
                            .padding()
                    } else if quoteVM.quotes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No quotes found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(quoteVM.quotes) { quote in
                                NavigationLink(destination: QuoteDetailView(quote: quote, quoteVM: quoteVM, favoriteVM: favoriteVM)) {
                                    QuoteCard(
                                        quote: quote,
                                        userId: sessionManager.session?.user.id ?? UUID(),
                                        favoriteVM: favoriteVM
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if quoteVM.hasMore {
                                ProgressView()
                                    .onAppear {
                                        Task { await quoteVM.loadQuotes() }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("QuoteVault")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch.toggle() }) {
                        Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                    }
                }
            }
            .refreshable {
                await quoteVM.loadDailyQuote()
                await quoteVM.loadQuotes(refresh: true)
            }
            .task {
                await quoteVM.loadDailyQuote()
                await quoteVM.loadQuotes(refresh: true)
            }
        }
    }
}

struct DailyQuoteCard: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Quote of the Day")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text("\"\(quote.text)\"")
                .font(.title3)
                .fontWeight(.medium)
                .padding(.vertical, 8)
            
            Text("- \(quote.author)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

struct QuoteCard: View {
    let quote: Quote
    let userId: UUID
    @ObservedObject var favoriteVM: FavoriteViewModel
    @State private var showingShareSheet = false
    @State private var showingCollections = false
    
    private var isFavorite: Bool {
        favoriteVM.isFavoriteSync(quoteId: quote.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\"\(quote.text)\"")
                        .font(.body)
                        .lineSpacing(4)
                    
                    HStack {
                        Text("- \(quote.author)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(quote.category)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                Button(action: {
                    Task {
                        _ = await favoriteVM.toggleFavorite(quoteId: quote.id, userId: userId)
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: { showingCollections = true }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: ["\"\(quote.text)\" - \(quote.author)"])
        }
        .sheet(isPresented: $showingCollections) {
            CollectionSelectionView(quoteId: quote.id, userId: userId)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct QuoteDetailView: View {
    let quote: Quote
    @ObservedObject var quoteVM: QuoteViewModel
    @ObservedObject var favoriteVM: FavoriteViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var suggestedQuotes: [Quote] = []
    @State private var isLoadingSuggestions = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Quote
                VStack(alignment: .leading, spacing: 16) {
                    Text("\"\(quote.text)\"")
                        .font(.title2)
                        .fontWeight(.medium)
                        .lineSpacing(6)
                    
                    HStack {
                        Text("- \(quote.author)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(quote.category)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Similar Quotes Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Similar Quotes")
                        .font(.headline)
                    
                    if isLoadingSuggestions {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if suggestedQuotes.isEmpty {
                        Text("No similar quotes found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(suggestedQuotes) { suggestedQuote in
                            NavigationLink(destination: QuoteDetailView(quote: suggestedQuote, quoteVM: quoteVM, favoriteVM: favoriteVM)) {
                                SuggestionQuoteRow(quote: suggestedQuote)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Quote")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSuggestions()
        }
    }
    
    private func loadSuggestions() async {
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }
        
        // Load quotes from same category (excluding current quote)
        do {
            let quotes: [Quote] = try await SupabaseManager.shared.client
                .from("quotes")
                .select()
                .eq("category", value: quote.category)
                .neq("id", value: quote.id.uuidString)
                .limit(5)
                .execute()
                .value
            
            suggestedQuotes = quotes
        } catch {
            print("Error loading suggestions: \(error)")
        }
    }
}

struct SuggestionQuoteRow: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            Text("- \(quote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

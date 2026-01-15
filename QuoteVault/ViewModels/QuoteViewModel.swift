//
//  QuoteViewModel.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation
import Supabase

@MainActor
class QuoteViewModel: ObservableObject {
    @Published var quotes: [Quote] = []
    @Published var dailyQuote: Quote?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 0
    @Published var hasMore = true
    @Published var selectedCategory: String? = nil
    @Published var searchText: String = ""
    @Published var searchAuthor: String = ""
    
    private let pageSize = AppConstants.Pagination.pageSize
    private var useLocalQuotes = true  // Always use local quotes (Supabase tables not setup)
    
    func loadQuotes(refresh: Bool = false) async {
        if refresh {
            currentPage = 0
            quotes = []
            hasMore = true
        }
        
        guard hasMore else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // If already using local quotes, continue with local
        if useLocalQuotes {
            loadLocalQuotes(refresh: refresh)
            return
        }
        
        // Try Supabase first, fallback to local quotes
        do {
            var query = SupabaseManager.shared.client
                .from(AppConstants.Strings.quotesTable)
                .select()
            
            if let category = selectedCategory, !category.isEmpty {
                query = query.eq("category", value: category)
            }
            
            if !searchText.isEmpty {
                query = query.ilike("text", pattern: "%\(searchText)%")
            }
            
            if !searchAuthor.isEmpty {
                query = query.ilike("author", pattern: "%\(searchAuthor)%")
            }
            
            let from = currentPage * pageSize
            let to = from + pageSize - 1
            let orderedQuery = query.order("created_at", ascending: false)
            let response: [Quote] = try await orderedQuery.range(from: from, to: to).execute().value
            
            if refresh {
                quotes = response
            } else {
                quotes.append(contentsOf: response)
            }
            
            hasMore = response.count == pageSize
            currentPage += 1
        } catch {
            print("Supabase error, using local quotes: \(error)")
            useLocalQuotes = true
            loadLocalQuotes(refresh: refresh)
        }
    }
    
    private func loadLocalQuotes(refresh: Bool) {
        var filteredQuotes = Self.localQuotes
        
        // Apply category filter
        if let category = selectedCategory, !category.isEmpty {
            filteredQuotes = filteredQuotes.filter { $0.category == category }
        }
        
        // Apply text search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filteredQuotes = filteredQuotes.filter { 
                $0.text.lowercased().contains(searchLower) 
            }
        }
        
        // Apply author search filter
        if !searchAuthor.isEmpty {
            let authorLower = searchAuthor.lowercased()
            filteredQuotes = filteredQuotes.filter { 
                $0.author.lowercased().contains(authorLower) 
            }
        }
        
        // For refresh, show all filtered results
        if refresh {
            quotes = filteredQuotes
            hasMore = false
            currentPage = 1
        } else {
            let from = currentPage * pageSize
            let to = min(from + pageSize, filteredQuotes.count)
            
            if from < filteredQuotes.count {
                let pageQuotes = Array(filteredQuotes[from..<to])
                quotes.append(contentsOf: pageQuotes)
                hasMore = to < filteredQuotes.count
                currentPage += 1
            } else {
                hasMore = false
            }
        }
    }
    
    func loadDailyQuote() async {
        // Use local quotes for daily quote
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        dailyQuote = Self.localQuotes[dayOfYear % Self.localQuotes.count]
    }
    
    func searchQuotes() async {
        await loadQuotes(refresh: true)
    }
    
    // MARK: - Local Quotes (100+ quotes across 5 categories)
    static let localQuotes: [Quote] = [
        // Motivation (20)
        Quote(id: UUID(), text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Motivation"),
        Quote(id: UUID(), text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", category: "Motivation"),
        Quote(id: UUID(), text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Motivation"),
        Quote(id: UUID(), text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", category: "Motivation"),
        Quote(id: UUID(), text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius", category: "Motivation"),
        Quote(id: UUID(), text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair", category: "Motivation"),
        Quote(id: UUID(), text: "The only impossible journey is the one you never begin.", author: "Tony Robbins", category: "Motivation"),
        Quote(id: UUID(), text: "Success usually comes to those who are too busy to be looking for it.", author: "Henry David Thoreau", category: "Motivation"),
        Quote(id: UUID(), text: "Don't be afraid to give up the good to go for the great.", author: "John D. Rockefeller", category: "Motivation"),
        Quote(id: UUID(), text: "I find that the harder I work, the more luck I seem to have.", author: "Thomas Jefferson", category: "Motivation"),
        Quote(id: UUID(), text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney", category: "Motivation"),
        Quote(id: UUID(), text: "If you are working on something exciting, you don't have to be pushed.", author: "Steve Jobs", category: "Motivation"),
        Quote(id: UUID(), text: "People who are crazy enough to think they can change the world are the ones who do.", author: "Rob Siltanen", category: "Motivation"),
        Quote(id: UUID(), text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford", category: "Motivation"),
        Quote(id: UUID(), text: "The secret of getting ahead is getting started.", author: "Mark Twain", category: "Motivation"),
        Quote(id: UUID(), text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison", category: "Motivation"),
        Quote(id: UUID(), text: "A person who never made a mistake never tried anything new.", author: "Albert Einstein", category: "Motivation"),
        Quote(id: UUID(), text: "There is only one way to avoid criticism: do nothing, say nothing, and be nothing.", author: "Aristotle", category: "Motivation"),
        Quote(id: UUID(), text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb", category: "Motivation"),
        Quote(id: UUID(), text: "Your limitation—it's only your imagination.", author: "Unknown", category: "Motivation"),
        
        // Love (20)
        Quote(id: UUID(), text: "The best thing to hold onto in life is each other.", author: "Audrey Hepburn", category: "Love"),
        Quote(id: UUID(), text: "Love is composed of a single soul inhabiting two bodies.", author: "Aristotle", category: "Love"),
        Quote(id: UUID(), text: "Where there is love there is life.", author: "Mahatma Gandhi", category: "Love"),
        Quote(id: UUID(), text: "The greatest thing you'll ever learn is just to love and be loved in return.", author: "Eden Ahbez", category: "Love"),
        Quote(id: UUID(), text: "Love all, trust a few, do wrong to none.", author: "William Shakespeare", category: "Love"),
        Quote(id: UUID(), text: "Being deeply loved by someone gives you strength, while loving someone deeply gives you courage.", author: "Lao Tzu", category: "Love"),
        Quote(id: UUID(), text: "The only thing we never get enough of is love; and the only thing we never give enough of is love.", author: "Henry Miller", category: "Love"),
        Quote(id: UUID(), text: "Love is not about how many days, months, or years you have been together. Love is about how much you love each other every single day.", author: "Unknown", category: "Love"),
        Quote(id: UUID(), text: "To love and be loved is to feel the sun from both sides.", author: "David Viscott", category: "Love"),
        Quote(id: UUID(), text: "Love is when the other person's happiness is more important than your own.", author: "H. Jackson Brown Jr.", category: "Love"),
        Quote(id: UUID(), text: "In the end, the love you take is equal to the love you make.", author: "Paul McCartney", category: "Love"),
        Quote(id: UUID(), text: "Love recognizes no barriers.", author: "Maya Angelou", category: "Love"),
        Quote(id: UUID(), text: "The heart has its reasons which reason knows not.", author: "Blaise Pascal", category: "Love"),
        Quote(id: UUID(), text: "Love is friendship that has caught fire.", author: "Ann Landers", category: "Love"),
        Quote(id: UUID(), text: "A loving heart is the truest wisdom.", author: "Charles Dickens", category: "Love"),
        Quote(id: UUID(), text: "Love is the only force capable of transforming an enemy into a friend.", author: "Martin Luther King Jr.", category: "Love"),
        Quote(id: UUID(), text: "Keep love in your heart. A life without it is like a sunless garden.", author: "Oscar Wilde", category: "Love"),
        Quote(id: UUID(), text: "The giving of love is an education in itself.", author: "Eleanor Roosevelt", category: "Love"),
        Quote(id: UUID(), text: "Love is a canvas furnished by nature and embroidered by imagination.", author: "Voltaire", category: "Love"),
        Quote(id: UUID(), text: "There is no remedy for love but to love more.", author: "Henry David Thoreau", category: "Love"),
        
        // Success (20)
        Quote(id: UUID(), text: "Success is walking from failure to failure with no loss of enthusiasm.", author: "Winston Churchill", category: "Success"),
        Quote(id: UUID(), text: "The road to success and the road to failure are almost exactly the same.", author: "Colin R. Davis", category: "Success"),
        Quote(id: UUID(), text: "Success is not the key to happiness. Happiness is the key to success.", author: "Albert Schweitzer", category: "Success"),
        Quote(id: UUID(), text: "Success is getting what you want. Happiness is wanting what you get.", author: "Dale Carnegie", category: "Success"),
        Quote(id: UUID(), text: "The successful warrior is the average man, with laser-like focus.", author: "Bruce Lee", category: "Success"),
        Quote(id: UUID(), text: "Success is not in what you have, but who you are.", author: "Bo Bennett", category: "Success"),
        Quote(id: UUID(), text: "Don't be distracted by criticism. Remember, the only taste of success some people get is to take a bite out of you.", author: "Zig Ziglar", category: "Success"),
        Quote(id: UUID(), text: "Success is liking yourself, liking what you do, and liking how you do it.", author: "Maya Angelou", category: "Success"),
        Quote(id: UUID(), text: "The only place where success comes before work is in the dictionary.", author: "Vidal Sassoon", category: "Success"),
        Quote(id: UUID(), text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier", category: "Success"),
        Quote(id: UUID(), text: "Coming together is a beginning; keeping together is progress; working together is success.", author: "Henry Ford", category: "Success"),
        Quote(id: UUID(), text: "Success consists of going from failure to failure without loss of enthusiasm.", author: "Winston Churchill", category: "Success"),
        Quote(id: UUID(), text: "Try not to become a man of success. Rather become a man of value.", author: "Albert Einstein", category: "Success"),
        Quote(id: UUID(), text: "Success is not measured by what you accomplish, but by the opposition you have encountered.", author: "Orison Swett Marden", category: "Success"),
        Quote(id: UUID(), text: "The secret of success is to do the common thing uncommonly well.", author: "John D. Rockefeller Jr.", category: "Success"),
        Quote(id: UUID(), text: "Success is simple. Do what's right, the right way, at the right time.", author: "Arnold H. Glasow", category: "Success"),
        Quote(id: UUID(), text: "Success is a journey, not a destination.", author: "Ben Sweetland", category: "Success"),
        Quote(id: UUID(), text: "Action is the foundational key to all success.", author: "Pablo Picasso", category: "Success"),
        Quote(id: UUID(), text: "Success is doing ordinary things extraordinarily well.", author: "Jim Rohn", category: "Success"),
        Quote(id: UUID(), text: "There are no secrets to success. It is the result of preparation, hard work, and learning from failure.", author: "Colin Powell", category: "Success"),
        
        // Wisdom (20)
        Quote(id: UUID(), text: "The only true wisdom is in knowing you know nothing.", author: "Socrates", category: "Wisdom"),
        Quote(id: UUID(), text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein", category: "Wisdom"),
        Quote(id: UUID(), text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu", category: "Wisdom"),
        Quote(id: UUID(), text: "Knowledge speaks, but wisdom listens.", author: "Jimi Hendrix", category: "Wisdom"),
        Quote(id: UUID(), text: "The fool doth think he is wise, but the wise man knows himself to be a fool.", author: "William Shakespeare", category: "Wisdom"),
        Quote(id: UUID(), text: "It is the mark of an educated mind to be able to entertain a thought without accepting it.", author: "Aristotle", category: "Wisdom"),
        Quote(id: UUID(), text: "The only thing I know is that I know nothing.", author: "Socrates", category: "Wisdom"),
        Quote(id: UUID(), text: "Wisdom is not a product of schooling but of the lifelong attempt to acquire it.", author: "Albert Einstein", category: "Wisdom"),
        Quote(id: UUID(), text: "By three methods we may learn wisdom: by reflection, by imitation, and by experience.", author: "Confucius", category: "Wisdom"),
        Quote(id: UUID(), text: "Turn your wounds into wisdom.", author: "Oprah Winfrey", category: "Wisdom"),
        Quote(id: UUID(), text: "The wise man does at once what the fool does finally.", author: "Niccolo Machiavelli", category: "Wisdom"),
        Quote(id: UUID(), text: "Patience is the companion of wisdom.", author: "Saint Augustine", category: "Wisdom"),
        Quote(id: UUID(), text: "The measure of intelligence is the ability to change.", author: "Albert Einstein", category: "Wisdom"),
        Quote(id: UUID(), text: "Knowing yourself is the beginning of all wisdom.", author: "Aristotle", category: "Wisdom"),
        Quote(id: UUID(), text: "The art of being wise is knowing what to overlook.", author: "William James", category: "Wisdom"),
        Quote(id: UUID(), text: "Wisdom begins in wonder.", author: "Socrates", category: "Wisdom"),
        Quote(id: UUID(), text: "A wise man can learn more from a foolish question than a fool can learn from a wise answer.", author: "Bruce Lee", category: "Wisdom"),
        Quote(id: UUID(), text: "Science is organized knowledge. Wisdom is organized life.", author: "Immanuel Kant", category: "Wisdom"),
        Quote(id: UUID(), text: "The doorstep to the temple of wisdom is a knowledge of our own ignorance.", author: "Benjamin Franklin", category: "Wisdom"),
        Quote(id: UUID(), text: "We are made wise not by the recollection of our past, but by the responsibility for our future.", author: "George Bernard Shaw", category: "Wisdom"),
        
        // Humor (20)
        Quote(id: UUID(), text: "I'm not superstitious, but I am a little stitious.", author: "Michael Scott", category: "Humor"),
        Quote(id: UUID(), text: "Behind every great man is a woman rolling her eyes.", author: "Jim Carrey", category: "Humor"),
        Quote(id: UUID(), text: "I'm not arguing, I'm just explaining why I'm right.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "I used to think I was indecisive, but now I'm not so sure.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "I'm on a seafood diet. I see food and I eat it.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "The only mystery in life is why the kamikaze pilots wore helmets.", author: "Al McGuire", category: "Humor"),
        Quote(id: UUID(), text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison", category: "Humor"),
        Quote(id: UUID(), text: "Life is short. Smile while you still have teeth.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "I'm not lazy, I'm just on energy-saving mode.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "Common sense is like deodorant. The people who need it most never use it.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "I don't need a hair stylist, my pillow gives me a new hairstyle every morning.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "My wallet is like an onion. Opening it makes me cry.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "I'm not short, I'm concentrated awesome.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "Age is something that doesn't matter unless you are a cheese.", author: "Luis Bunuel", category: "Humor"),
        Quote(id: UUID(), text: "I'm writing a book. I've got the page numbers done.", author: "Steven Wright", category: "Humor"),
        Quote(id: UUID(), text: "I told my wife she was drawing her eyebrows too high. She looked surprised.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "I'm not clumsy, the floor just hates me.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "If at first you don't succeed, then skydiving definitely isn't for you.", author: "Steven Wright", category: "Humor"),
        Quote(id: UUID(), text: "I'm not weird, I'm a limited edition.", author: "Unknown", category: "Humor"),
        Quote(id: UUID(), text: "My bed is a magical place where I suddenly remember everything I forgot to do.", author: "Unknown", category: "Humor"),
    ]
}

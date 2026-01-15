//
//  AppConstants.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation

enum AppConstants {
    enum Strings {
        static let appName = "QuoteVault"
        static let quotesTable = "quotes"
        static let favoritesTable = "user_favorites"
        static let collectionsTable = "collections"
        static let collectionQuotesTable = "collection_quotes"
        static let profilesTable = "profiles"
    }
    
    enum Categories {
        static let motivation = "Motivation"
        static let love = "Love"
        static let success = "Success"
        static let wisdom = "Wisdom"
        static let humor = "Humor"
        
        static let all: [String] = [motivation, love, success, wisdom, humor]
    }
    
    enum Notification {
        static let dailyQuoteIdentifier = "dailyQuote"
        static let defaultNotificationHour = 9
        static let defaultNotificationMinute = 0
    }
    
    enum Pagination {
        static let pageSize = 20
    }
    
    enum Theme {
        static let defaultTheme = "default"
        static let blue = "blue"
        static let purple = "purple"
    }
}

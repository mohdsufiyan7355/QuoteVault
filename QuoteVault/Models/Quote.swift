//
//  Quote.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let author: String
    let category: String
    let createdAt: Date?
    let isDailyQuote: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, text, author, category
        case createdAt = "created_at"
        case isDailyQuote = "is_daily_quote"
    }
    
    init(id: UUID = UUID(), text: String, author: String, category: String, createdAt: Date? = nil, isDailyQuote: Bool? = nil) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
        self.createdAt = createdAt
        self.isDailyQuote = isDailyQuote
    }
}


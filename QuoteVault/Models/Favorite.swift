//
//  Favorite.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation

struct Favorite: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let quoteId: UUID
    let createdAt: Date
}

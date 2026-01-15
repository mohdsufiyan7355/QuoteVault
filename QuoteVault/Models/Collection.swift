//
//  Collection.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation

struct Collection: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date
}

struct CollectionQuote: Identifiable, Codable {
    let id: UUID
    let collectionId: UUID
    let quoteId: UUID
    let addedAt: Date
}

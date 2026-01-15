//
//  UserProfile.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import Foundation

struct UserProfile: Codable {
    let id: UUID
    let userId: UUID
    let name: String?
    let avatarUrl: String?
    let theme: String?
    let fontSize: Double?
    let notificationTime: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(id: UUID = UUID(), userId: UUID, name: String? = nil, avatarUrl: String? = nil, theme: String? = nil, fontSize: Double? = nil, notificationTime: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.avatarUrl = avatarUrl
        self.theme = theme
        self.fontSize = fontSize
        self.notificationTime = notificationTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


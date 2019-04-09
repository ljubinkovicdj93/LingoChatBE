// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

final class Chat: Codable {
    // MARK: - Primary Key
    var id: UUID?

    // MARK: - Foreign keys
    var languageID: Language.ID
    var createdByUserID: User.ID

    // MARK: - Properties
    var name: String
    var createdAt: Date
    
    // MARK: - Initialization
    init(name: String,
         createdAt: Date,
         languageID: Language.ID,
         createdByUserID: User.ID) {
        self.name = name
        self.createdAt = createdAt
        
        self.languageID = languageID
        self.createdByUserID = createdByUserID
    }
}

// MARK: - Extensions
extension Chat: PostgreSQLUUIDModel {}
extension Chat: Content {}
extension Chat: Migration {
    // Foreign key constraints
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.createdByUserID, to: \User.id)
            builder.reference(from: \.languageID, to: \Language.id)
        }
    }
}
extension Chat: Parameter {}

// Relations
extension Chat {
    var languageUsedInChat: Parent<Chat, Language> {
        return parent(\.languageID)
    }
    
    var userWhoCreatedChat: Parent<Chat, User> {
        return parent(\.createdByUserID)
    }
    
    var users: Siblings<Chat, User, UserChatPivot> {
        return siblings()
    }
}

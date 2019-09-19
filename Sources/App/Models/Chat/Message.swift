//
//  Message.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/19/19.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Message: Codable {
    // MARK: - Properties
    var id: UUID?
    var text: String
    var createdAt: Double?
    
    // MARK: - Foreign Keys
    var userId: User.ID
    var chatId: Chat.ID
    
    // MARK: - Initialization
    init(text: String, userId: User.ID, chatId: Chat.ID, createdAt: Double = Date().timeIntervalSince1970) {
        self.text = text
        self.userId = userId
        self.chatId = chatId
        self.createdAt = createdAt
    }
}

extension Message: PostgreSQLUUIDModel {}
extension Message: Content {}
extension Message: Parameter {}

// MARK: - Parent-child relationship
extension Message {
    var user: Parent<Message, User> {
        return parent(\.userId)
    }
    
    var chat: Parent<Message, Chat> {
        return parent(\.chatId)
    }
}

// MARK: - Foreign-Key Constraints
extension Message: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            
            // Sets the foreign-key constraint between the two tables.
            builder.reference(from: \.userId, to: \User.id)
            builder.reference(from: \.chatId, to: \Chat.id)
        }
    }
}

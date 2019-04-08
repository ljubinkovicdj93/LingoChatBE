// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

// Use Int here to easily conform an enum to Codable.
enum MessageType: Int, Codable {
    case text
    case image
    case audio
    case video
}

final class Message: Codable {
    // MARK: - Primary key
    var id: UUID?
    
    // MARK: - Foreign keys
    var userChatID: UserChatPivot.ID
    var userLanguageID: UserLanguagePivot.ID
    
    // MARK: - Properties
    var messageText: String
    var messageType: MessageType
    var isTranslated: Bool
    var translatedMessageText: String
    var createdAt: Date
    
    // MARK: - Initialization
    init(messageText: String,
         messageType: MessageType,
         isTranslated: Bool,
         translatedMessageText: String,
         createdAt: Date,
         userChatID: UserChatPivot.ID,
         userLanguageID: UserLanguagePivot.ID) {
        self.messageText = messageText
        self.messageType = messageType
        self.isTranslated = isTranslated
        self.translatedMessageText = translatedMessageText
        self.createdAt = createdAt
        
        self.userLanguageID = userLanguageID
        self.userChatID = userChatID
    }
}

// MARK: - Extensions
extension Message: PostgreSQLUUIDModel {}
extension Message: Content {}
extension Message: Migration {}
extension Message: Parameter {}

// MARK: Relations
extension Message {
    /// Chat that has this message.
    var chat: Parent<Message, UserChatPivot> {
        return parent(\.userChatID)
    }
    
    /// Language in which the message is written in.
    var language: Parent<Message, UserLanguagePivot> {
        return parent(\.userLanguageID)
    }
}

// Project: LingoChatBE
//
// Created on Friday, April 05, 2019.
// 

import FluentPostgreSQL
import Vapor

final class UserChatPivot: PostgreSQLUUIDPivot {
    // MARK: - Primary Key
    var id: UUID?

    // MARK: - Foreign keys
    var userID: User.ID
    var chatID: Chat.ID
    var userLanguageID: UserLanguagePivot.ID?
    
    // MARK: - Properties
    var createdAt: Date?
    
    typealias Left = User
    typealias Right = Chat
    
    static let leftIDKey: LeftIDKey = \.userID
    static let rightIDKey: RightIDKey = \.chatID
    
    // MARK: - Initialization
    init(_ user: User, _ chat: Chat) throws {
        self.userID = try user.requireID()
        self.chatID = try chat.requireID()
    }
    
    convenience init(user: User,
                     chat: Chat,
                     userLanguageID: UserLanguagePivot.ID?,
                     createdAt: Date?) throws {
        do {
            try self.init(user, chat)
            self.userLanguageID = userLanguageID
            self.createdAt = createdAt
        } catch {
            fatalError("UserChatPivot initialization error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Extensions
extension UserChatPivot: Content {}
extension UserChatPivot: Parameter {}
extension UserChatPivot: Migration {}
extension UserChatPivot: ModifiablePivot {}

// MARK: Relations
extension UserChatPivot {
    var messages: Children<UserChatPivot, Message> {
        return children(\.userChatID)
    }
    
    var language: Parent<UserChatPivot, UserLanguagePivot>? {
        return parent(\.userLanguageID)
    }
}


//
//  UserChatPivot.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import FluentPostgreSQL
import Foundation

final class UserChatPivot: PostgreSQLUUIDPivot {
    // MARK: - Properties
    var participantId: User.ID
    
    // MARK: - Primary Key
    var id: UUID?
    
    // MARK: - Foreign Keys
    /// Creator of the chat.
    var userId: User.ID
    var chatId: Chat.ID
    
    typealias Left = User
    typealias Right = Chat
    
    static var leftIDKey: LeftIDKey = \.userId
    static var rightIDKey: RightIDKey = \.chatId
    
    init(user: User, chat: Chat, participant: User) throws {
        self.userId = try user.requireID()
        self.chatId = try chat.requireID()
        self.participantId = try participant.requireID()
    }
}

extension UserChatPivot: Migration {
//    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            
////            builder.unique(on: \.userId, \.chatId)
//            
//            builder.reference(from: \.userId, to: \User.id, onDelete: .cascade)
//            builder.reference(from: \.chatId, to: \Chat.id, onDelete: .cascade)
//        }
//    }
}

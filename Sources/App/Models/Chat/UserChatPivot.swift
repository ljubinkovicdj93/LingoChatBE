//
//  UserChatPivot.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import FluentPostgreSQL
import Foundation

final class UserChatPivot: PostgreSQLUUIDPivot {
    var id: UUID?
    
    var userId: User.ID
    var chatId: Chat.ID
    
    typealias Left = User
    typealias Right = Chat
    
    static var leftIDKey: LeftIDKey = \.userId
    static var rightIDKey: RightIDKey = \.chatId
    
    init(_ user: User, _ chat: Chat) throws {
        self.userId = try user.requireID()
        self.chatId = try chat.requireID()
    }
}

extension UserChatPivot: ModifiablePivot {}
extension UserChatPivot: Migration {}

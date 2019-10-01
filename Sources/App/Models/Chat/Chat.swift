//
//  Chat.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Chat: Codable {
    var id: UUID?
    var name: String
    var createdAt: Double?
    
    init(name: String, createdAt: Double = Date().timeIntervalSince1970) {
        self.name = name
        self.createdAt = createdAt
    }
}

extension Chat: PostgreSQLUUIDModel {}
extension Chat: Content {}
extension Chat: Parameter {}
extension Chat: Migration {}

// MARK: - Parent-child relationship (one-to-many)
extension Chat {
    var messages: Children<Chat, Message> {
        return children(\.chatId)
    }
}

// MARK: - Sibling relationship (many-to-many)
extension Chat {
    // It returns the siblings of a Chat that are of type User and held using the UserChatPivot.
    var users: Siblings<Chat,
        User,
        UserChatPivot> {
        return siblings()
    }
    
//    static func addChat(_ name: String,
//                        to user: User,
//                        on req: Request) throws -> Future<Void> {
//        return Chat
//            .query(on: req)
//            .filter(\.name == name)
//            .first()
//            .flatMap(to: Void.self) { foundChat in
//                if let existingChat = foundChat {
//                    return user.chats
//                        .attach(existingChat, on: req)
//                        .transform(to: ())
//                } else {
//                    let chat = Chat(name: name)
//                    
//                    return chat.save(on: req).flatMap(to: Void.self) { newChat in
//                        return user.chats
//                            .attach(newChat, on: req)
//                            .transform(to: ())
//                    }
//                }
//        }
//    }
}

struct ChatCreateData: Content {
    let name: String?
    let participants: [User.Public] // Array of Users
    
    init(name: String = "", participants: [User.Public]) {
        self.name = name
        self.participants = participants
    }
}

struct ChatDTO: Content {
    let chat: Chat
    let participants: [User.Public]?
    let lastMessage: String?
}

extension ChatCreateData: Validatable, Reflectable {
    static func validations() throws -> Validations<ChatCreateData> {
        var validations = Validations(ChatCreateData.self)
        
        try validations.add(\.participants, !.empty)
        
        return validations
    }
}

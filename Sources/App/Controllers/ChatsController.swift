// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct ChatsController: RouteCollection {
    func boot(router: Router) throws {
        let chatsRoutes = router.grouped("api", "chats")
        
        // Creatable
        chatsRoutes.post(Chat.self, use: createHandler)
        
        // Retrievable
        chatsRoutes.get(use: getAllHandler)
        chatsRoutes.get(Chat.parameter, use: getHandler)
        chatsRoutes.get("first", use: getFirstHandler)
        
        // Updatable
        chatsRoutes.put(Chat.parameter, use: updateHandler)
        
        // Deletable
        chatsRoutes.delete(Chat.parameter, use: deleteHandler)
        
        // Relational endpoints
        // Language(s)
        chatsRoutes.get(Chat.parameter, "language", use: getLanguageHandler)
        
        // User(s)
        chatsRoutes.get(Chat.parameter, "creator", use: getCreatorUserHandler)
        chatsRoutes.get(Chat.parameter, "users", use: getAllUsersHandler)
    }
}

// MARK: - CRUDRepresentable & Queryable
extension ChatsController: CRUDRepresentable, Queryable {
    typealias T = Chat
    
    func updateHandler(_ req: Request) throws -> Future<Chat> {
        return try flatMap(
            to: Chat.self,
            req.parameters.next(Chat.self),
            req.content.decode(Chat.self)
        ) { chat, updatedChat in
            chat.languageID = updatedChat.languageID
            chat.createdByUserID = updatedChat.createdByUserID
            chat.name = updatedChat.name
            chat.createdAt = updatedChat.createdAt
            
            return chat.save(on: req)
        }
    }
}

// MARK: - Languages related methods
extension ChatsController {
    func getLanguageHandler(_ req: Request) throws -> Future<Language> {
        return try req.parameters.next(Chat.self)
            .flatMap(to: Language.self) { chat in
                chat.languageUsedInChat.get(on: req)
        }
    }
}

// MARK: - Users related methods
extension ChatsController {
    func getCreatorUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Chat.self)
            .flatMap(to: User.self) { chat in
                chat.userWhoCreatedChat.get(on: req)
        }
    }
    
    func getAllUsersHandler(_ req: Request) throws -> Future<[User]> {
        return try req.parameters.next(Chat.self)
            .flatMap(to: [User].self) { chat in
                try chat.users.query(on: req).all()
        }
    }
}

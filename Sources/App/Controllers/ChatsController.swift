// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent
import Authentication

struct ChatsController: RouteCollection {
    typealias T = Chat
    typealias U = Chat
    
    func boot(router: Router) throws {
        let chatsRoutes = router.grouped("api", "chats")
        
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
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let protected = chatsRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
        // Creatable
        // Only requests authenticated using HTTP authentication can create chats.
        protected.post(Chat.self, use: createHandler)
    }
}

// MARK: - CRUDRepresentable & Queryable
extension ChatsController: CRUDRepresentable, Queryable {
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
    func getCreatorUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Chat.self)
            .flatMap(to: User.Public.self) { chat in
                chat.userWhoCreatedChat.get(on: req).convertToPublic()
        }
    }
    
    func getAllUsersHandler(_ req: Request) throws -> Future<[User.Public]> {
        return try req.parameters.next(Chat.self)
            .flatMap(to: [User.Public].self) { chat in
                try chat.users.query(on: req).decode(data: User.Public.self).all()
        }
    }
}

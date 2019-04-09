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
        
        // Relational endpoints
        // Language(s)
        chatsRoutes.get(Chat.parameter, "language", use: getLanguageHandler)
        
        // User(s)
        chatsRoutes.get(Chat.parameter, "creator", use: getCreatorUserHandler)
        chatsRoutes.get(Chat.parameter, "users", use: getAllUsersHandler)
        
        // Authentication Middleware
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = chatsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

        // Ensure only requests authenticated using HTTP token authentication can create, update, and delete chats.
        tokenAuthGroup.post(ChatCreateData.self, use: createChatHander)
        tokenAuthGroup.put(Chat.parameter, use: updateHandler)
        tokenAuthGroup.delete(Chat.parameter, use: deleteHandler)
    }
    
    func createChatHander(_ req: Request, data: ChatCreateData) throws -> Future<Chat> {
        let user = try req.requireAuthenticated(User.self)
        let chat = try Chat(name: data.name,
                            createdAt: data.createdAt,
                            languageID: data.languageID,
                            createdByUserID: user.requireID())
        
        return chat.save(on: req)
    }
}

struct ChatCreateData: Content {
    let languageID: Language.ID
    let name: String
    let createdAt: Date
}

// MARK: - CRUDRepresentable & Queryable
extension ChatsController: Retrievable, Updatable, Deletable, Queryable {
    func updateHandler(_ req: Request) throws -> Future<Chat> {
        return try flatMap(
            to: Chat.self,
            req.parameters.next(Chat.self),
            req.content.decode(ChatCreateData.self)
        ) { chat, updatedChatData in
            chat.languageID = updatedChatData.languageID
            chat.name = updatedChatData.name
            chat.createdAt = updatedChatData.createdAt
            
            let user = try req.requireAuthenticated(User.self)
            chat.createdByUserID = try user.requireID()
            
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

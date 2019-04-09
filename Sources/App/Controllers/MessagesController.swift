// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct MessagesController: RouteCollection {
    typealias T = Message
    typealias U = Message
    
    func boot(router: Router) throws {
        let messagesRoutes = router.grouped("api", "messages")
        
        // Retrievable
        messagesRoutes.get(use: getAllHandler)
        messagesRoutes.get(Message.parameter, use: getHandler)
        messagesRoutes.get("first", use: getFirstHandler)
        
        // Relational endpoints
        // Chat(s)
        messagesRoutes.get(Message.parameter, "chat", use: getUserChatHandler)
        
        // Language(s)
        messagesRoutes.get(Message.parameter, "language", use: getUserLanguageHandler)
        
        // Authentication Middleware
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = messagesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        // Ensure only requests authenticated using HTTP token authentication can create, update, and delete messages.
        tokenAuthGroup.post(Message.self, use: createHandler)
        tokenAuthGroup.put(Message.parameter, use: updateHandler)
        tokenAuthGroup.delete(Message.parameter, use: deleteHandler)
    }
}

// MARK: - CRUDRepresentable & Queryable
extension MessagesController: CRUDRepresentable, Queryable {
    func updateHandler(_ req: Request) throws -> Future<Message> {
        return try flatMap(
            to: Message.self,
            req.parameters.next(Message.self),
            req.content.decode(Message.self)
        ) { message, updatedMessage in
            message.userChatID = updatedMessage.userChatID
            message.userLanguageID = updatedMessage.userLanguageID
            message.messageText = updatedMessage.messageText
            message.messageType = updatedMessage.messageType
            message.isTranslated = updatedMessage.isTranslated
            message.translatedMessageText = updatedMessage.translatedMessageText
            message.createdAt = updatedMessage.createdAt
            
            return message.save(on: req)
        }
    }
}

// MARK: - User Languages related methods
extension MessagesController {
    func getUserLanguageHandler(_ req: Request) throws -> Future<UserLanguagePivot> {
        return try req.parameters.next(Message.self)
            .flatMap(to: UserLanguagePivot.self) { message in
                message.language.get(on: req)
        }
    }
}

// MARK: - User Chats related methods
extension MessagesController {
    func getUserChatHandler(_ req: Request) throws -> Future<UserChatPivot> {
        return try req.parameters.next(Message.self)
            .flatMap(to: UserChatPivot.self) { message in
                message.chat.get(on: req)
        }
    }
}

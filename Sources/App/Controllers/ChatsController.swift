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
        chatsRoutes.get(Message.parameter, use: getHandler)
        chatsRoutes.get("first", use: getFirstHandler)
        
        // Updatable
        chatsRoutes.put(Message.parameter, use: updateHandler)
        
        // Deletable
        chatsRoutes.delete(Message.parameter, use: deleteHandler)
    }
}

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

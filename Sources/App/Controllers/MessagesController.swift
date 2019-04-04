// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct MessagesController: RouteCollection {
    func boot(router: Router) throws {
        let messagesRoutes = router.grouped("api", "messages")
        
        messagesRoutes.get(use: getAllMessagesHandler)
    }
    
    func getAllMessagesHandler(_ req: Request) throws -> Future<[Message]> {
        return Message.query(on: req).all()
    }
}

// Project: LingoChatBE
//
// Created on Monday, April 08, 2019.
// 

import Vapor
import Fluent

struct UserChatsController: RouteCollection {
    func boot(router: Router) throws {
        let userChatsRoutes = router.grouped("api", "user-chats")
        
        userChatsRoutes.get(use: getAllUserChatsHandler)
        
        userChatsRoutes.delete(UserChatPivot.parameter, use: deleteFriendshipHandler)
    }
    
    func getAllUserChatsHandler(_ req: Request) throws -> Future<[UserChatPivot]> {
        return UserChatPivot.query(on: req).all()
    }
    
    func deleteFriendshipHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(UserChatPivot.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
}


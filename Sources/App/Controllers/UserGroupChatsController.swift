// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
//

import Vapor
import Fluent

struct UserGroupChatsController: RouteCollection {
    func boot(router: Router) throws {
        let userGroupChatsRoutes = router.grouped("api", "user-group-chats")
        
        userGroupChatsRoutes.get(use: getAllUserGroupChatsHandler)
    }
    
    func getAllUserGroupChatsHandler(_ req: Request) throws -> Future<[UserGroupChat]> {
        return UserGroupChat.query(on: req).all()
    }
}

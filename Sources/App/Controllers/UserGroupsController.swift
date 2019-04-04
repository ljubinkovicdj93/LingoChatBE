// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct UserGroupsController: RouteCollection {
    func boot(router: Router) throws {
        let userGroupsRoutes = router.grouped("api", "user-groups")
        
        userGroupsRoutes.get(use: getAllUserGroupsHandler)
    }
    
    func getAllUserGroupsHandler(_ req: Request) throws -> Future<[UserGroup]> {
        return UserGroup.query(on: req).all()
    }
}

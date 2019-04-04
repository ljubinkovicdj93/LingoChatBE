// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct GroupsController: RouteCollection {
    func boot(router: Router) throws {
        let groupsController = router.grouped("api", "groups")
        
        groupsController.get(use: getAllGroupsHandler)
    }
    
    func getAllGroupsHandler(_ req: Request) throws -> Future<[Group]> {
        return Group.query(on: req).all()
    }
}


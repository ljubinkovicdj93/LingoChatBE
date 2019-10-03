//
//  UsersController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct UsersControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "v2", "users")
        
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, use: getHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return try User
            .query(on: req)
            .paginate(on: req)
            .decode(data: User.Public.self)
            .all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).public
    }
}

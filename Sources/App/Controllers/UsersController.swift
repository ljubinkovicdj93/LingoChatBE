// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoutes = router.grouped("api", "users")
        
        usersRoutes.post(User.self, use: createUserHandler)
        usersRoutes.get(use: getAllUsersHandler)
    }
    
    func createUserHandler(_ req: Request, user: User) throws -> Future<HTTPStatus> {
        return user.save(on: req).transform(to: .created)
    }
    
    func getAllUsersHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
}

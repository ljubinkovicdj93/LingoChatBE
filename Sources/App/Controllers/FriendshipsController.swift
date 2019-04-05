// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct FriendshipsController: RouteCollection {
    typealias T = User
    
    func boot(router: Router) throws {
        let friendshipRoutes = router.grouped("api", "friendships")
        
        // Creates a sibling relationship between the user with <USER_ID> and the friend with <USER_ID>
        friendshipRoutes.post(User.parameter, "befriend", User.parameter, use: addFriendHandler)
    }
    
    // Relations
    func addFriendHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(User.self),
                           req.parameters.next(User.self)) { user, friend in
                            return try FriendshipPivot(user, friend).save(on: req).transform(to: .created)
        }
    }
}

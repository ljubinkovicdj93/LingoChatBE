// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct FriendshipsController: RouteCollection {
    func boot(router: Router) throws {
        let friendshipRoutes = router.grouped("api", "friendships")
        
        friendshipRoutes.get(use: getAllFriendshipsHandler)
        
        friendshipRoutes.delete(FriendshipPivot.parameter, use: deleteFriendshipHandler)
    }
    
    func getAllFriendshipsHandler(_ req: Request) throws -> Future<[FriendshipPivot]> {
        return FriendshipPivot.query(on: req).all()
    }
    
    func deleteFriendshipHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(FriendshipPivot.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
}

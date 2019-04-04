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
    }
    
    func getAllFriendshipsHandler(_ req: Request) throws -> Future<[Friendship]> {
        return Friendship.query(on: req).all()
    }
}

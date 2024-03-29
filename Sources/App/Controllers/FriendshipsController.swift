//
//  FriendshipsController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/19/19.
//

import Vapor
import Fluent

struct FriendshipsController: RouteCollection {
    func boot(router: Router) throws {
        let friendshipRoutes = router.grouped("api", "friendships")
        
        friendshipRoutes.group(JWTMiddleware.self) { jwtGroup in
            jwtGroup.get(use: getAllFriendshipsHandler)
        }
        
//        friendshipRoutes.get(use: getAllFriendshipsHandler)
        
        friendshipRoutes.delete(FriendshipPivot.parameter, use: deleteFriendshipHandler)
    }
    
    func getAllFriendshipsHandler(_ req: Request) throws -> Future<[FriendshipPivot]> {
        return FriendshipPivot
            .query(on: req)
            .filter(\.chatId, .isNot, nil)
            .all()
    }
    
    func deleteFriendshipHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(FriendshipPivot.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
}

struct FriendDTO: Content {
    let friend: User.Public?
    let chatId: Chat.ID?
}

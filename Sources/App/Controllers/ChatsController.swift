//
//  ChatsController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct ChatsController: RouteCollection {
    func boot(router: Router) throws {
        let chatsRoute = router.grouped("api", "chats")
        
        // Protected routes
        #warning("TODO: Find a way to do this in a middleware.")
        // Use https://github.com/skelpo/JWTMiddleware
        chatsRoute.get(use: getAllHandler)
        chatsRoute.get(Chat.parameter, "users", use: getUsersHandler)
        
        #warning("TODO: REFACTOR")
//        chatsRoute.get(User.parameter, use: getUserChatUserMessagesHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Chat]> {
        // Fetches the token from `Authorization: Bearer <token>` header
        guard req.http.headers.bearerAuthorization != nil else { throw Abort(.unauthorized) }
        
        return Chat
            .query(on: req)
            .all()
    }
    
    func getUsersHandler(_ req: Request) throws -> Future<[User.Public]> {
        return try req.parameters.next(Chat.self).flatMap(to: [User.Public].self) { chat in
            return try chat.users.query(on: req).decode(data: User.Public.self).all()
        }
    }
    
    #warning("TODO: REFACTOR")
//    func getUserChatUserMessagesHandler(_ req: Request) throws -> Future<[Message]> {
//        let userPayload = try req.userPayload()
//
//        return FriendshipPivot
//            .query(on: req)
//            .group(.and) { queryBuilder in
//                queryBuilder.aggregate(\FriendshipPivot., field: <#T##KeyPath<Chat, T>#>)
//        }
//    }
}

extension Request {
    func userPayload() throws -> User {
        // Fetches the token from `Authorization: Bearer <token>` header
        guard let bearer = self.http.headers.bearerAuthorization else {
            throw Abort(.unauthorized)
        }
        
        // parse JWT from token string, using HS-256 signer
        let jwt = try JWT<User>(from: bearer.token,
                                verifiedUsing: .hs256(key: "secret"))
        let user = jwt.payload
        
        return user
    }
}

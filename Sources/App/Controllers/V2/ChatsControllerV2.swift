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

struct ChatsControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let chatsRoute = router.grouped("api", "v2", "chats").grouped(JWTMiddleware())
        
        // Protected routes
        #warning("TODO: Find a way to do this in a middleware.")
        // Use https://github.com/skelpo/JWTMiddleware
//        chatsRoute.get(use: getAllHandler)
        chatsRoute.get(use: getUserChatUserMessagesHandler)
        chatsRoute.get(Chat.parameter, "users", use: getUsersHandler)
        
        #warning("TODO: REFACTOR")
        chatsRoute.get(User.parameter, use: getUserChatUserMessagesHandler)
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
    
    func getUserChatUserMessagesHandler(_ req: Request) throws -> Future<[Chat]> {
        return try req.authorizedUser().flatMap(to: [Chat].self) { authenticatedUser in
            return try authenticatedUser.chats.query(on: req).all()
        }
    }
}

extension Request {
    func userPayloadV2() throws -> User {
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

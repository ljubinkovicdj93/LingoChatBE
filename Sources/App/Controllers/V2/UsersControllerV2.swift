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
        usersRoute.post(User.self, use: createHandler)
        
        // Authentication related
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        // There is no guard authentication middleware since requireAuthenticated(_:)
        // throws the correct error if a user isn't authenticated.
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    func loginHandler(_ req: Request) throws -> Future<AccessDTO> {
        // Get the authenticated user from the request. Saves the user's identity in the request's authentication cache, allowing us to retrieve the user object later.
        let user = try req.requireAuthenticated(User.self)
        
        return try createJWT(req, from: user)
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<AccessDTO> {
        user.password = try BCrypt.hash(user.password)
        return user
            .save(on: req)
            .public
            .flatMap(to: AccessDTO.self) { savedUser in
                return try self.createJWT(req, from: user)
        }
    }
    
    /// Creates JWT and signs it.
    private func createJWT(_ req: Request, from user: User, secret: String = "secret") throws -> Future<AccessDTO> {
        let accessToken = try TokenHelpers.createAccessToken(from: user)
        let expiredAt = try TokenHelpers.expiredDate(of: accessToken)
        let accessDto = AccessDTO(accessToken: accessToken, expiredAt: expiredAt)
        
        return req.future(accessDto)
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
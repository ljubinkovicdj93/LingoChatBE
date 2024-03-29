//
//  AccountControllerV2.swift
//  App
//
//  Created by Djordje Ljubinkovic on 10/3/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct AccountControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let accountRoute = router.grouped("api", "v2", "account")
        
        accountRoute.post(User.self, use: createHandler)
        accountRoute.post(RefreshTokenDTO.self, at: "refreshToken", use: refreshToken)
        
        // Authentication related
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        // There is no guard authentication middleware since requireAuthenticated(_:)
        // throws the correct error if a user isn't authenticated.
        let basicAuthGroup = accountRoute.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
        
        let protected = accountRoute.grouped(JWTMiddleware())
        
        protected.put(UserUpdateData.self, use: updateHandler)
        protected.delete(use: deleteHandler)
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
        let refreshToken = TokenHelpers.createRefreshToken()
        
        let accessDto = AccessDTO(refreshToken: refreshToken, accessToken: accessToken, expiredAt: expiredAt)
        
        return RefreshToken(token: refreshToken, userID: try user.requireID())
            .save(on: req)
            .transform(to: accessDto)
    }
    
    func updateHandler(_ req: Request, data: UserUpdateData) throws -> Future<HTTPStatus> {
        return try req.authorizedUser().flatMap(to: HTTPStatus.self) { authenticatedUser in
            authenticatedUser.firstName = data.firstName
            authenticatedUser.lastName = data.lastName
            authenticatedUser.username = data.username
            authenticatedUser.email = data.email
            authenticatedUser.password = data.password
            
            return authenticatedUser.update(on: req).transform(to: .ok)
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.authorizedUser().flatMap(to: HTTPStatus.self) { authenticatedUser in
            return authenticatedUser.delete(on: req).transform(to: .noContent)
        }
    }
    
    // MARK: - Token
    func refreshToken(_ req: Request, refreshTokenDto: RefreshTokenDTO) throws -> Future<AccessDTO> {
        let refreshTokenModel = RefreshToken
            .query(on: req)
            .filter(\.token, .equal, refreshTokenDto.refreshToken)
            .first()
            .unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.expiredAt > Date() {
                return refreshTokenModel.user.get(on: req).flatMap { user in
                    let accessToken = try TokenHelpers.createAccessToken(from: user)
                    let refreshToken = TokenHelpers.createRefreshToken()
                    let expiredAt = try TokenHelpers.expiredDate(of: accessToken)
                    
                    refreshTokenModel.token = refreshToken
                    refreshTokenModel.updateExpiredDate()
                    
                    let accessDto = AccessDTO(refreshToken: refreshToken, accessToken: accessToken, expiredAt: expiredAt)
                    
                    return refreshTokenModel.save(on: req).transform(to: accessDto)
                }
            } else {
                return refreshTokenModel.delete(on: req).thenThrowing {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
}

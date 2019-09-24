//
//  RefreshTokenControllerV2.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct RefreshTokenControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let refreshTokenRoute = router.grouped("api", "v2")
        
        refreshTokenRoute.post(RefreshTokenDTO.self, at: "refreshToken", use: refreshToken)
    }
    
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

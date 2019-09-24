//
//  JWTMiddleware.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/23/19.
//

import Vapor
import JWT

final class JWTMiddleware: Middleware {
    let secret: String
    
    init(secret: String = JWTConfig.signerKey) {
        self.secret = secret
    }
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        guard let token = request.http.headers.bearerAuthorization?.token else { throw Abort(.unauthorized, reason: "No Authorization header (Bearer) present.") }
        
        // parse JWT from token string, using HS-256 signer
        do {
            try TokenHelpers.verifyToken(token)
            
            return try next.respond(to: request)
        } catch {
            let reason = "ERROR_JWT_MIDDLEWARE: \(error.localizedDescription)"
            throw Abort(.unauthorized, reason: reason)
        }
    }
}

extension JWTMiddleware: ServiceType {
    static func makeService(for container: Container) throws -> JWTMiddleware {
        return .init(secret: JWTConfig.signerKey)
    }
}

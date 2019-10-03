//
//  Request+token.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import Vapor
import JWT

extension Request {
    var token: String {
        if let token = self.http.headers.bearerAuthorization?.token {
            return token
        } else {
            return ""
        }
    }
    
    func authorizedUser() throws -> Future<User> {
//        let userID = try TokenHelpers.getUserID(fromPayloadOf: self.token)
        guard let userID = try TokenHelpers.getUser(fromPayloadOf: self.token).id else {
            throw JWTError.payloadCreation
        }
        
        return User.find(userID, on: self).unwrap(or: Abort(.unauthorized, reason: "Authorized user not found"))
    }
}

//
//  JWTError.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import JWT

extension JWTError {
    static let payloadCreation = JWTError(identifier: "TokenHelpers.createPayload", reason: "User ID not found")
    static let createJWT = JWTError(identifier: "TokenHelpers.createJWT", reason: "Error getting token string")
    static let verificationFailed = JWTError(identifier: "TokenHelpers.verifyToken", reason: "JWT verification failed")
}

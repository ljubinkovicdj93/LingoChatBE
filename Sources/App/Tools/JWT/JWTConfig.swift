//
//  JWTConfig.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import JWT

enum JWTConfig {
    static let signerKey = "secret" // Key for signing JWT Access Token
    static let header = JWTHeader(alg: "HS256", typ: "JWT") // Algorithm and Type
    static let signer = JWTSigner.hs256(key: JWTConfig.signerKey) // Signer for JWT
    static let expirationTime: TimeInterval = 100 // In seconds
}

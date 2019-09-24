//
//  AccessTokenPayload.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import Vapor
import JWT

struct AccessTokenPayload: JWTPayload {
    
    var issuer: IssuerClaim
    var issuedAt: IssuedAtClaim
    var expirationAt: ExpirationClaim
    var userID: User.ID
    
    init(issuer: String = "LingoChatBasicApp",
         issuedAt: Date = Date(),
         expirationAt: Date = Date().addingTimeInterval(JWTConfig.expirationTime),
         userID: User.ID) {
        self.issuer = IssuerClaim(value: issuer)
        self.issuedAt = IssuedAtClaim(value: issuedAt)
        self.expirationAt = ExpirationClaim(value: expirationAt)
        self.userID = userID
    }
    
    func verify(using signer: JWTSigner) throws {
        try self.expirationAt.verifyNotExpired()
    }
}

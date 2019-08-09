// Project: LingoChatBE
//
// Created on Tuesday, April 09, 2019.
// 

import Foundation
import JWT
import Vapor
import FluentPostgreSQL
import Authentication

final class Token: Codable {
    var id: UUID?
    /// Token string provided to clients.
    var token: String
    /// Token owner's user ID.
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: PostgreSQLUUIDModel {}
extension Token: Content {}
extension Token: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Token {
    /// Generates a Token for the User.
    ///
    /// - Parameters:
    ///   - user: User to generate the Token for.
    ///   - byteCount: Number of bytes used to act as a Token.
    /// - Returns: Token with the base64-encoded representation of the random bytes and the user's ID.
    static func generate(for user: User, byteCount: Int = 16) throws -> Token {
//        let random = try CryptoRandom().generateData(count: byteCount)
//        return try Token(token: random.base64EncodedString(),
//                         userID: user.requireID())
        
        let publicUser = user.createPublicUser()
								.set(exp: Date(timeIntervalSince1970: 1558785600.0))
								.set(iss: "DJORDJE THE KING")
								.set(iat: Date())
								.set(aud: ["Djole, Ana, Djole-Ana's Pet, etc..."])
		
        print("publicUser.id:", publicUser.id?.uuidString)
		print("PUBLIC_USER:", publicUser)

        // Create JWT and sign
        let data = try JWT(payload: publicUser).sign(using: .hs256(key: "secret"))
     
        guard let jwtString = String(data: data, encoding: .utf8) else {
            fatalError("Could not generate JWT string!")
        }
        
        return try Token(token: jwtString,
                         userID: user.requireID())
    }
}

// MARK: - Authentication
extension Token: Authentication.Token {
    typealias UserType = User
    static var userIDKey: WritableKeyPath<Token, Token.UserIDType> = \Token.userID
}

extension Token: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<Token, String> = \Token.token
}

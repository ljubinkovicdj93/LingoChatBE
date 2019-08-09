// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor
import Authentication
import JWT

protocol FullNameRepresentable {
    var fullName: String { get }
}

final class User: Codable {
    var id: UUID?
    var firstName: String
    var lastName: String
    var email: String
    var username: String?
    var password: String
    var photoUrl: String?
    var friendCount: Int?
    
    init(firstName: String,
         lastName: String,
         email: String,
         username: String? = nil,
         password: String,
         photoUrl: String? = nil,
         friendCount: Int? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.password = password
        self.photoUrl = photoUrl
        self.friendCount = friendCount
    }

    func createPublicUser() -> User.Public {
        return User.Public(id: self.id,
                           firstName: self.firstName,
                           lastName: self.lastName,
                           email: self.email,
                           username: self.username,
                           photoUrl: self.photoUrl,
                           friendCount: self.friendCount)
    }
    
    /// Inner class to represent a public view of User.
    final class Public: Codable {
        var id: UUID?
        var firstName: String
        var lastName: String
        var email: String
        var username: String?
        var photoUrl: String?
        var friendCount: Int?
		
		// MARK: - JWT Claims
		
		var aud: [String]?
		var iss: String?
		var sub: String?
		var jit: String?
		var exp: Date?
		var nbf: Date?
		var iat: Date?
        
        init(id: UUID?,
             firstName: String,
             lastName: String,
             email: String,
             username: String? = nil,
             photoUrl: String? = nil,
             friendCount: Int? = nil) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.username = username
            self.photoUrl = photoUrl
            self.friendCount = friendCount
        }
		
		// MARK: - Builder Pattern
		@discardableResult
		func set(iss: String) -> User.Public {
			self.iss = iss
			return self
		}
		
		@discardableResult
		func set(sub: String) -> User.Public {
			self.sub = sub
			return self
		}
		
		@discardableResult
		func set(jit: String) -> User.Public {
			self.jit = jit
			return self
		}
		
		@discardableResult
		func set(aud: [String]) -> User.Public {
			self.aud = aud
			return self
		}
		
		
		@discardableResult
		func set(exp: Date) -> User.Public {
			self.exp = exp
			return self
		}
		
		@discardableResult
		func set(nbf: Date) -> User.Public {
			self.nbf = nbf
			return self
		}
		
		@discardableResult
		func set(iat: Date) -> User.Public {
			self.iat = iat
			return self
		}
    }
}

// MARK: - Extensions

// MARK: - JWTPayload
extension User.Public: JWTPayload {
    func verify(using signer: JWTSigner) throws {
        // TODO: - Doesn't include any claims, so leave empty for now. Re-implement.
    }
}

// MARK: - Authentication
extension User: BasicAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> = \User.email
    static var passwordKey: WritableKeyPath<User, String> = \User.password
}

// MARK: - Database related
extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.email)
            builder.unique(on: \.username)
        }
    }
}
extension User: Parameter {}

// MARK: - Public User View
extension User.Public: Content {} // Allows displaying public view in responses.

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id,
                           firstName: firstName,
                           lastName: lastName,
                           email: email,
                           username: username,
                           photoUrl: photoUrl,
                           friendCount: friendCount)
    }
}

extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

// MARK: - Relations
extension User {
    var chatsCreatedByThisUser: Children<User, Chat> {
        return children(\.createdByUserID)
    }
    
    var languages: Siblings<User, Language, UserLanguagePivot> {
        return siblings()
    }
    
    var chats: Siblings<User, Chat, UserChatPivot> {
        return siblings()
    }
    
    // Friends of the user
    var friends: Siblings<User, User, FriendshipPivot> {
        return siblings(FriendshipPivot.leftIDKey, FriendshipPivot.rightIDKey)
    }
    
    // Users who have friended the user
    var friendOf: Siblings<User, User, FriendshipPivot> {
        return siblings(FriendshipPivot.rightIDKey, FriendshipPivot.leftIDKey)
    }
}

// MARK: - Authentication
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

extension User.Public: FullNameRepresentable {
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

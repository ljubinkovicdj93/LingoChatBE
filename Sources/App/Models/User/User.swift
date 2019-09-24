import Foundation
import Vapor
import FluentPostgreSQL
import Authentication
import JWT

protocol FullNameRepresentable {
    var fullName: String { get }
}

final class User: Codable {
    var id: UUID?
    var email: String
    var username: String
    var password: String
    var firstName: String
    var lastName: String
    
    init(firstName: String, lastName: String, username: String, password: String, email: String) {
        self.email = email
        self.username = username
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
    
    /// Public view of the User (to return in response(s))
    final class Public: Codable, FullNameRepresentable {
        var id: UUID?
        var username: String
        var firstName: String
        var lastName: String
        
        // MARK: - FullNameRepresentable
        var fullName: String {
            return "\(firstName) \(lastName)"
        }
        
        // MARK: - Initialization
        init(id: UUID?, username: String, firstName: String, lastName: String) {
            self.id = id
            self.username = username
            self.firstName = firstName
            self.lastName = lastName
        }
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        guard
            let lId = lhs.id,
            let rId = rhs.id
        else { fatalError("IDs must exist!") }
        
        return lId == rId
    }
}

extension User: PostgreSQLUUIDModel {}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content {}
/// Allows `User.Public` to be encoded to and decoded from HTTP messages.
extension User.Public: Content {}

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter {}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        // Creates the User table.
        return Database.create(self, on: conn) { builder in
            // Adds all the columns to the User table using User's properties.
            try addProperties(to: builder)
            
            // Ensures that .username property is UNIQUE. Adds a unique index to username on User.
            builder.unique(on: \.username)
            // Ensures that .email property is UNIQUE. Adds a unique index to email on User.
            builder.unique(on: \.email)
        }
    }
}

// MARK: - Sibling relationship (many-to-many)
extension User {
    var chats: Siblings<User, Chat, UserChatPivot> {
        return siblings()
    }
    
    var friends: Siblings<User, User, FriendshipPivot> {
        return siblings(FriendshipPivot.leftIDKey, FriendshipPivot.rightIDKey)
    }
    
    static func addUser(_ userId: UUID,
                        to chat: Chat,
                        on req: Request) throws -> Future<Void> {
        return User
            .query(on: req)
            .filter(\.id == userId)
            .first()
            .flatMap(to: Void.self) { foundUser in
                if let existingUser = foundUser {
                    return chat.users
                        .attach(existingUser, on: req)
                        .transform(to: ())
                } else {
                    throw Abort(.internalServerError)
                }
        }
    }
}

// MARK: - Helpers
extension User {
    /// Returns a public version of the User.
    var `public`: User.Public {
        return User.Public(id: id,
                           username: username,
                           firstName: firstName,
                           lastName: lastName)
    }
}

extension User.Public: ReflectionDecodable {
    static func reflectDecodedIsLeft(_ item: User.Public) throws -> Bool {
        return true
    }
    
    static func reflectDecoded() throws -> (User.Public, User.Public) {
        let left = User.Public(id: UUID(),
                               username: "username1",
                               firstName: "first1",
                               lastName: "last1")
        let right = User.Public(id: UUID(),
                                username: "username2",
                                firstName: "first2",
                                lastName: "last2")
        return (left, right)
    }
}

extension Future where T: User {
    /// Returns a Future of a public version of the User.
    var `public`: Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.public
        }
    }
}

// MARK: - Authentication
extension User: BasicAuthenticatable {
    static var usernameKey: UsernameKey = \User.email
    static var passwordKey: PasswordKey = \User.password
}

// MARK: - JWT
#warning("TODO: Refactor")
extension User {
    /// Public view of the User to return in JWT.
    /// Includes email as well.
    final class JWTUserView: Codable, JWTPayload {
        var id: UUID?
        var username: String
        var firstName: String
        var lastName: String
        var email: String
        
        // MARK: - FullNameRepresentable
        var fullName: String {
            return "\(firstName) \(lastName)"
        }
        
        // MARK: - Initialization
        init(id: UUID?, username: String, firstName: String, lastName: String, email: String) {
            self.id = id
            self.username = username
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
        }
        
        func verify(using signer: JWTSigner) throws {
            // Nothing to verify since our payload doesn't include any claims.
        }
    }
    
    var jwtPublic: JWTUserView {
        return JWTUserView(id: id,
                           username: username,
                           firstName: firstName,
                           lastName: lastName,
                           email: email)
    }
}

struct JWTResponse: Content {
    let token: String
}

extension User: JWTPayload {
    func verify(using signer: JWTSigner) throws {
        // Nothing to verify since our payload doesn't include any claims.
    }
}

// MARK: - Refresh Token
extension User {
    var refreshTokens: Children<User, RefreshToken> {
        return self.children(\.userID)
    }
}

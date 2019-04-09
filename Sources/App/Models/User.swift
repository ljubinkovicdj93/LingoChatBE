// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor
import Authentication

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
    
    /// Inner class to represent a public view of User.
    final class Public: Codable {
        var id: UUID?
        var firstName: String
        var lastName: String
        var email: String
        var username: String?
        var photoUrl: String?
        var friendCount: Int?
        
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
    }
}

// MARK: - Extensions

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

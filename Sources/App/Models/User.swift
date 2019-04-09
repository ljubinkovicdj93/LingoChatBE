// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

final class User: Codable {
    var id: UUID?
    var firstName: String
    var lastName: String
    var email: String
    var username: String?
    var password: String
    var photoUrl: URL?
    var friendCount: Int?
    
    init(firstName: String,
         lastName: String,
         email: String,
         username: String? = nil,
         password: String,
         photoUrl: URL? = nil,
         friendCount: Int? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.password = password
        self.photoUrl = photoUrl
        self.friendCount = friendCount
    }
}

// MARK: - Extensions
extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}

// Relations
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

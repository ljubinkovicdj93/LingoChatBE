// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import FluentPostgreSQL
import Vapor

final class FriendshipPivot: PostgreSQLUUIDPivot {
    // MARK: - Primary Key
    var id: UUID?
    
    // MARK: - Foreign keys
    var userID: User.ID
    var friendID: User.ID
    
    typealias Left = User
    typealias Right = User
    
    static var leftIDKey: LeftIDKey = \.userID
    static var rightIDKey: RightIDKey = \.friendID
    
    // MARK: - Initialization
    init(_ user: User, _ friend: User) throws {
        self.userID = try user.requireID()
        self.friendID = try friend.requireID()
    }
}

// MARK: - Extensions
extension FriendshipPivot: Content {}
extension FriendshipPivot: Parameter {}
extension FriendshipPivot: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            
            builder.reference(from: \.userID, to: \User.id, onDelete: .cascade)
            builder.reference(from: \.friendID, to: \User.id, onDelete: .cascade)
        }
    }
}
extension FriendshipPivot: ModifiablePivot {}

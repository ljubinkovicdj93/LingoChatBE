//
//  FriendshipsPivot.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import Vapor
import FluentPostgreSQL

final class FriendshipPivot: PostgreSQLUUIDPivot {
    enum FriendRequestStatus: Int, PostgreSQLRawEnum {
        case declined = -1
        case pending = 0
        case approved = 1
    }
    
    // MARK: - Properties
    var status: FriendRequestStatus
    
    // MARK: - Primary Key
    var id: UUID?
    
    // MARK: - Foreign keys
    var userId: User.ID
    var friendId: User.ID
    
    typealias Left = User
    typealias Right = User
    
    static var leftIDKey: LeftIDKey = \.userId
    static var rightIDKey: RightIDKey = \.friendId
    
    // MARK: - Initialization
    init(user: User, friend: User, status: FriendRequestStatus) throws {
        self.userId = try user.requireID()
        self.friendId = try friend.requireID()
        self.status = status
    }
}

// MARK: - Extensions
extension FriendshipPivot: Content {}
extension FriendshipPivot: Parameter {}
extension FriendshipPivot: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            
            builder.unique(on: \.userId, \.friendId)
            builder.unique(on: \.friendId, \.userId)
            
            builder.reference(from: \.userId, to: \User.id, onDelete: .cascade)
            builder.reference(from: \.friendId, to: \User.id, onDelete: .cascade)
        }
    }
}

struct FriendRequestUpdateData: Content {
    let status: Int
}

extension FriendRequestUpdateData: Validatable, Reflectable {
    static func validations() throws -> Validations<FriendRequestUpdateData> {
        var validations = Validations(FriendRequestUpdateData.self)
        
        try validations.add(\.status, .range(-1...1))
        
        return validations
    }
}

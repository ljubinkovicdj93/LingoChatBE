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
    var chatId: Chat.ID?
    
    // MARK: - Primary Key
    var id: UUID?
    
    // MARK: - Foreign keys
    var senderId: User.ID
    var receiverId: User.ID
    
    typealias Left = User
    typealias Right = User
    
    static var leftIDKey: LeftIDKey = \.senderId
    static var rightIDKey: RightIDKey = \.receiverId
    
    // MARK: - Initialization
    init(user: User, friend: User, status: FriendRequestStatus, chatId: Chat.ID? = nil) throws {
        self.senderId = try user.requireID()
        self.receiverId = try friend.requireID()
        self.status = status
        self.chatId = chatId
    }
}

// MARK: - Extensions
extension FriendshipPivot: Content {}
extension FriendshipPivot: Parameter {}
extension FriendshipPivot: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            
            builder.unique(on: \.senderId, \.receiverId)
            builder.unique(on: \.receiverId, \.senderId)
            
            builder.reference(from: \.senderId, to: \User.id, onDelete: .cascade)
            builder.reference(from: \.receiverId, to: \User.id, onDelete: .cascade)
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

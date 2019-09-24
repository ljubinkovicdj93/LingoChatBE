//
//  RefreshToken.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import Vapor
import FluentPostgreSQL

final class RefreshToken: PostgreSQLUUIDModel {
    fileprivate enum Constants {
        static let refreshTokenTime: TimeInterval = 60 * 24 * 60 * 60
    }
    
    var id: UUID?
    var token: String
    var expiredAt: Date
    var userID: User.ID
    
    init(id: UUID? = nil, token: String, expiredAt: Date = Date().addingTimeInterval(Constants.refreshTokenTime), userID: User.ID) {
        self.id = id
        self.token = token
        self.expiredAt = expiredAt
        self.userID = userID
    }
    
    func updateExpiredDate() {
        self.expiredAt = Date().addingTimeInterval(Constants.refreshTokenTime)
    }
}

extension RefreshToken {
    var user: Parent<RefreshToken, User> {
        return self.parent(\.userID)
    }
}
extension RefreshToken: Content {}
extension RefreshToken: PostgreSQLMigration {}
extension RefreshToken: Parameter {}

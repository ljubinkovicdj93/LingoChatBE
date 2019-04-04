// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

final class UserGroup: Codable {
    var id: UUID?
    var userJoinedTimestamp: Date
    
    init(userJoinedTimestamp: Date) {
        self.userJoinedTimestamp = userJoinedTimestamp
    }
}

extension UserGroup: PostgreSQLUUIDModel {}
extension UserGroup: Content {}
extension UserGroup: Migration {}
extension UserGroup: Parameter {}

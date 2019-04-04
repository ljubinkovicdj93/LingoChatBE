// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

final class UserGroupChat: Codable {
    var id: UUID?
}

extension UserGroupChat: PostgreSQLUUIDModel {}
extension UserGroupChat: Content {}
extension UserGroupChat: Migration {}
extension UserGroupChat: Parameter {}

// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import FluentPostgreSQL
import Vapor

final class Friendship: Codable {
    var id: UUID?
}

extension Friendship: PostgreSQLUUIDModel {}
extension Friendship: Content {}
extension Friendship: Migration {}
extension Friendship: Parameter {}


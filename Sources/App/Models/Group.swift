// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

final class Group: Codable {
    var id: UUID?
    var name: String
    var timestamp: Date
    
    init(name: String, timestamp: Date) {
        self.name = name
        self.timestamp = timestamp
    }
}

extension Group: PostgreSQLUUIDModel {}
extension Group: Content {}
extension Group: Migration {}
extension Group: Parameter {}

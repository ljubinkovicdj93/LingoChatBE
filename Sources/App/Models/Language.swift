// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import FluentPostgreSQL
import Vapor

final class Language: Codable {
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Language: PostgreSQLModel {}
extension Language: Content {}
extension Language: Migration {}
extension Language: Parameter {}

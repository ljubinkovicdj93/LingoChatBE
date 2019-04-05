// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import FluentPostgreSQL
import Vapor

final class Language: Codable {
    // MARK: - Primary Key
    var id: Int?
    
    // MARK: - Foreign keys
    var userID: User.ID
    
    // MARK: - Properties
    var name: String
    
    // MARK: - Initialization
    init(name: String,
         userID: User.ID) {
        self.name = name
        self.userID = userID
    }
}

// MARK: - Extensions
extension Language: PostgreSQLModel {}
extension Language: Content {}
extension Language: Migration {
//    // Foreign key constraints
//    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.reference(from: \.userID, to: \User.id)
//        }
//    }
}
extension Language: Parameter {}

// MARK: - Relations
extension Language {
//    var user: Parent<Language, User> {
//        return parent(\.userID)
//    }
//
//    var messages: Children<Language, Message> {
//        return children(\.languageID)
//    }
}

// Project: LingoChatBE
//
// Created on Sunday, March 24, 2019.
// 

//import FluentSQLite
//import FluentMySQL
import FluentPostgreSQL
import Vapor

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
    }
}

//extension Acronym: Model {
//    typealias Database = SQLiteDatabase
//    typealias ID = Int
//    public static var idKey: IDKey = \Acronym.id // key path of the model's ID property.
//}

// Or just use this
//extension Acronym: SQLiteModel {}
//extension Acronym: MySQLModel {}
extension Acronym: PostgreSQLModel {}
extension Acronym: Migration {}
extension Acronym: Content {}
extension Acronym: Parameter {}

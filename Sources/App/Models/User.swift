// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

final class User: Codable {
    var id: UUID?
    var firstName: String
    var lastName: String
    var email: String
    var password: String
    var friendCount: Int
    var username: String?
    var photoUrl: URL?
    
    init(firstName: String, lastName: String, email: String, password: String, friendCount: Int = 0, username: String? = nil, photoUrl: URL? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.friendCount = friendCount
        self.username = username
        self.photoUrl = photoUrl
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}

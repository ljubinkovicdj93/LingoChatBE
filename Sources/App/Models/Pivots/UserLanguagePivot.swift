// Project: LingoChatBE
//
// Created on Monday, April 08, 2019.
// 

import FluentPostgreSQL
import Foundation

final class UserLanguagePivot: PostgreSQLUUIDPivot {
    // MARK: - Primary Key
    var id: UUID?
    
    // MARK: - Foreign keys
    var userID: User.ID
    var languageID: Language.ID
    
    typealias Left = User
    typealias Right = Language
    
    static let leftIDKey: LeftIDKey = \.userID
    static let rightIDKey: RightIDKey = \.languageID
    
    // MARK: - Initialization
    init(_ user: User, _ language: Language) throws {
        self.userID = try user.requireID()
        self.languageID = try language.requireID()
    }
}

// MARK: - Extensions
extension UserLanguagePivot: Migration {}
extension UserLanguagePivot: ModifiablePivot {}

// MARK: Relations
extension UserLanguagePivot {
    /// All the messages written in this language.
    var messages: Children<UserLanguagePivot, Message> {
        return children(\.userLanguageID)
    }
}

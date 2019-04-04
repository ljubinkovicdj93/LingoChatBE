// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Foundation
import FluentPostgreSQL
import Vapor

// Use Int here to easily conform an enum to Codable.
enum MessageType: Int, Codable {
    case text
    case image
    case audio
    case video
}

final class Message: Codable {
    var id: UUID?
    var messageText: String
    var messageTimestamp: Date
    var messageType: MessageType
    var isTranslated: Bool
    
    init(messageText: String, messageTimestamp: Date, messageType: MessageType, isTranslated: Bool) {
        self.messageText = messageText
        self.messageTimestamp = messageTimestamp
        self.messageType = messageType
        self.isTranslated = isTranslated
    }
}

extension Message: PostgreSQLUUIDModel {}
extension Message: Content {}
extension Message: Migration {}
extension Message: Parameter {}

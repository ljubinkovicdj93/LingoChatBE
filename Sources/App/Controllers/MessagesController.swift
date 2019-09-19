//
//  MessagesController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/19/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct MessagesController: RouteCollection {
    func boot(router: Router) throws {
        let messagesRoute = router.grouped("api", "messages")
    }
}

struct MessageCreateData: Content {
    #warning("TODO: Encrypt messages")
    let text: String
}

extension MessageCreateData: Validatable, Reflectable {
    static func validations() throws -> Validations<MessageCreateData> {
        var validations = Validations(MessageCreateData.self)
        
        try validations.add(\.text, !.empty)
        
        return validations
    }
}

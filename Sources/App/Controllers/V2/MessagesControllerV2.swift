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

struct MessagesControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let messagesRoute = router
            .grouped("api", "messages", "v2")
            .grouped(JWTMiddleware())
    }
}

struct MessageCreateDataV2: Content {
    #warning("TODO: Encrypt messages")
    let text: String
}

extension MessageCreateDataV2: Validatable, Reflectable {
    static func validations() throws -> Validations<MessageCreateDataV2> {
        var validations = Validations(MessageCreateDataV2.self)
        
        try validations.add(\.text, !.empty)
        
        return validations
    }
}

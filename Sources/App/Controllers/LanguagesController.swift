// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct LanguagesController: RouteCollection {
    func boot(router: Router) throws {
        let languagesRoutes = router.grouped("api", "languages")
        
        // Creatable
        languagesRoutes.post(Language.self, use: createHandler)
        
        // Retrievable
        languagesRoutes.get(use: getAllHandler)
        languagesRoutes.get(Language.parameter, use: getHandler)
        languagesRoutes.get("first", use: getFirstHandler)
        
        // Updatable
        languagesRoutes.put(Language.parameter, use: updateHandler)
        
        // Deletable
        languagesRoutes.delete(Language.parameter, use: deleteHandler)
        
        // Searchable
        languagesRoutes.get("search", use: searchHandler)
        
        // Sortable
        languagesRoutes.get("sorted", use: sortedHandler)
        
        // Relational endpoints
        // User(s)
        languagesRoutes.get(Language.parameter, "users", use: getAllUsersHandler)
        
        // Chat(s)
        languagesRoutes.get(Language.parameter, "chats", use: getAllChatsHandler)
    }
}

extension LanguagesController: CRUDRepresentable, Queryable {
    typealias T = Language
    
    func updateHandler(_ req: Request) throws -> Future<Language> {
        return try flatMap(
            to: Language.self,
            req.parameters.next(Language.self),
            req.content.decode(Language.self)
        ) { language, updatedLanguage in
            language.name = updatedLanguage.name
            language.userID = updatedLanguage.userID
            return language.save(on: req)
        }
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Language]> {
        guard let searchTerm = req
            .query[String.self, at: "term"] else {
                throw Abort(.badRequest)
        }
        return Language.query(on: req)
            .filter(\.name == searchTerm)
            .all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Language]> {
        return Language.query(on: req).sort(\.name, .ascending).all()
    }
}

// MARK: - Users related methods
extension LanguagesController {
    func getAllUsersHandler(_ req: Request) throws -> Future<[User]> {
        return try req.parameters.next(Language.self)
            .flatMap(to: [User].self) { language in
                try language.users.query(on: req).all()
        }
    }
}

// MARK: - Chats related methods
extension LanguagesController {
    func getAllChatsHandler(_ req: Request) throws -> Future<[Chat]> {
        return try req.parameters.next(Language.self)
            .flatMap(to: [Chat].self) { language in
                try language.chats.query(on: req).all()
        }
    }
}

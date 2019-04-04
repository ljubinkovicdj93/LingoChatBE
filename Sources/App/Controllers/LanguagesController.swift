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
        
        languagesRoutes.get(use: getAllLanguagesHandler)
        
        // Searchable
        languagesRoutes.get("search", use: searchHandler)
    }
    
    func getAllLanguagesHandler(_ req: Request) throws -> Future<[Language]> {
        return Language.query(on: req).all()
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


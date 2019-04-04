// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct LanguagesController: RouteCollection {
    func boot(router: Router) throws {
        let languagesRoutes = router.grouped("api", "languages")
        
        languagesRoutes.get(use: getAllLanguagesHandler)
    }
    
    func getAllLanguagesHandler(_ req: Request) throws -> Future<[Language]> {
        return Language.query(on: req).all()
    }
}


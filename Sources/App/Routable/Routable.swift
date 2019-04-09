// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

typealias CRUDRepresentable = Creatable & Retrievable & Updatable & Deletable
typealias Queryable = Searchable & Sortable

protocol Routable {
    associatedtype T where T: Content & Model & Parameter, T.ResolvedParameter == Future<T>
    associatedtype U where U: Content
}

protocol Creatable: Routable {
    func createHandler(_ req: Request, model: T) throws -> Future<U>
}

extension Creatable where T == U {
    func createHandler(_ req: Request, model: T) throws -> Future<U> {
        return model.save(on: req)
    }
}

protocol Retrievable: Routable {
    func getAllHandler(_ req: Request) throws -> Future<[U]>
    func getHandler(_ req: Request) throws -> Future<U>
    func getFirstHandler(_ req: Request) throws -> Future<U>
}

extension Retrievable where T == U {
    func getAllHandler(_ req: Request) throws -> Future<[U]> {
        return T.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<U> {
        return try req.parameters.next(T.self)
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<U> {
        return T.query(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
    }
}

protocol Updatable: Routable {
    func updateHandler(_ req: Request) throws -> Future<U>
}

protocol Deletable: Routable {
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus>
}

extension Deletable {
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(T.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
}

protocol Searchable: Routable {
    func searchHandler(_ req: Request) throws -> Future<[U]>
}

// Optional methods
extension Searchable {
    func searchHandler(_ req: Request) throws -> Future<[U]> { throw Abort(.notImplemented) }
}

protocol Sortable: Routable {
    func sortedHandler(_ req: Request) throws -> Future<[U]>
}

// Optional methods
extension Sortable {
    func sortedHandler(_ req: Request) throws -> Future<[U]> { throw Abort(.notImplemented) }
}

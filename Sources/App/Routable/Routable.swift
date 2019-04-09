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
}

protocol Creatable: Routable {
    func createHandler(_ req: Request, type: T) throws -> Future<T>
}

extension Creatable {
    func createHandler(_ req: Request, type: T) throws -> Future<T> {
        return type.save(on: req)
    }
}

protocol Retrievable: Routable {
    func getAllHandler(_ req: Request) throws -> Future<[T]>
    func getHandler(_ req: Request) throws -> Future<T>
    func getFirstHandler(_ req: Request) throws -> Future<T>
}

extension Retrievable {
    func getAllHandler(_ req: Request) throws -> Future<[T]> {
        return T.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<T> {
        return try req.parameters.next(T.self)
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<T> {
        return T.query(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
    }
}

protocol Updatable: Routable {
    func updateHandler(_ req: Request) throws -> Future<T>
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
    func searchHandler(_ req: Request) throws -> Future<[T]>
}

// Optional methods
extension Searchable {
    func searchHandler(_ req: Request) throws -> Future<[T]> { throw Abort(.notImplemented) }
}

protocol Sortable: Routable {
    func sortedHandler(_ req: Request) throws -> Future<[T]>
}

// Optional methods
extension Sortable {
    func sortedHandler(_ req: Request) throws -> Future<[T]> { throw Abort(.notImplemented) }
}

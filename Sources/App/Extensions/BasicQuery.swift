//
//  BasicQuery.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/20/19.
//

import Foundation
import Vapor
import Fluent

public struct BasicQuery: Codable {
    public let plain: Bool?
    public let page: Int?
    public let limit: Int?
    public let search: String?
}

extension QueryContainer {
    public var basic: BasicQuery? {
        let decoded = try? decode(BasicQuery.self)
        return decoded
    }
    
    public var plain: Bool? {
        return basic?.plain
    }
    
    public var page: Int? {
        return basic?.page
    }
    
    public var limit: Int? {
        return basic?.limit ?? 20
    }
    
    public var search: String? {
        return basic?.search
    }
    
}

//GET http://localhost:8080/api/users?limit=20&page=1
extension QueryBuilder {
    public func paginate(on req: Request) throws -> Self {
        if let limit = req.query.basic?.limit {
            let page = req.query.basic?.page ?? 1
            let lower = ((page - 1) * limit)
            return range(lower: lower, upper: (lower + (limit - 1)))
        }
        return self
    }
}

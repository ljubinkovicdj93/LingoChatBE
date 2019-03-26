import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    // http://localhost:8080/hello/vapor
    router.get("hello", "vapor") { req in // closure that runs when this route is invoked.
        return "Hello Vapor!"
    }
    
    // http://localhost:8080/hello/Djolence
    // Use String.parameter to specify that the second parameter can be any String.
    router.get("hello", String.parameter) { req -> String in
        // Extract the user's name, which is passed in the Request object.
        let name = try req.parameters.next(String.self)
        return "Hello, \(name)!"
    }
    
    // POST (sending data, as JSON for example)
//    router.post(InfoData.self, at: "info") { (req, data) -> String in
//        return "Hello \(data.name)!"
//    }

    // POST (sending data, as JSON for example) and returning JSON
    router.post(InfoData.self, at: "info") { (req, data) -> InfoResponse in
        return InfoResponse(request: data)
    }
    
    // MARK: - CRUD
    
    /*
         request data:
             {
                 "short": "OMG",
                 "long": "Oh My God"
             }
     
         response data:
             {
                 "id": 1,
                 "short": "OMG",
                 "long": "Oh My God"
             }
     */
    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self)
            .flatMap(to: Acronym.self) { acronym in
                return acronym.save(on: req)
        }
    }
    
    // Retrieve ALL acronyms
//    router.get("api", "acronyms") { req -> Future<[Acronym]> in
//        return Acronym.query(on: req).all() // equivalent to `SELECT * FROM Acronyms`
//    }
    
    // Update
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        
        // dual Future -> provides both the acronym from the db and acronym from the request body to the closure.
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(Acronym.self)) { acronym, updatedAcronym in
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                
                return acronym.save(on: req)
        }
    }
    
    // Delete
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
    // Retrieve a SINGLE acronyms
    // Registers a route at /api/acronyms/<ID> to handle a get request.
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }
    
    // MARK: - Queries
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
        return Acronym.query(on: req).filter(\.short == searchTerm).all()
    }
    
    // Multiple fields
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
        
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }
    
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        return Acronym.query(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    // MARK: - Sorting
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
    
    // MARK: - Controllers
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
}

// MARK: - OTHER

// Send JSON -> Return JSON

// For POST example:
// Content is Vapor's wrapper around Codable
struct InfoData: Content {
    let name: String
}

// JSON response for InfoData, from Vapor to the app
struct InfoResponse: Content {
    let request: InfoData
}

// Creating Futures

//func createTrackingSession(for request: Request) -> Future<TrackingSession> {
//    return request.makeNewSession()
//}
//
//func getTrackingSession(for request: Request)
//    -> Future<TrackingSession> {
//        // 3
//        let session: TrackingSession? =
//            TrackingSession(id: request.getKey())
//        // 4
//        guard let createdSession = session else {
//            return createTrackingSession(for: request)
//        }
//        // 5
//        return request.future(createdSession)
//}

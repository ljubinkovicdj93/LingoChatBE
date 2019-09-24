import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let lingoChatRouter = LingoChatRouter()
    
    // MARK: - Version 1
    try lingoChatRouter.registerRoutes(router, version: .v1)
    
    // MARK: - Version 2
    try lingoChatRouter.registerRoutes(router, version: .v2)
}

enum LingoChatVersion {
    case v1
    case v2
}

struct LingoChatRouter {
    static let v1Routes: [RouteCollection] = [
        UsersController(),
        ChatsController(),
        FriendshipsController()
    ]
    
    static let v2Routes: [RouteCollection] = [
        UsersControllerV2(),
        FriendshipsControllerV2(),
        ChatsControllerV2(),
        MessagesControllerV2(),
        RefreshTokenControllerV2()
    ]
    
    func registerRoutes(_ router: Router, version: LingoChatVersion) throws {
        do {
            switch version {
            case .v1:
                try LingoChatRouter.v1Routes.forEach { try router.register(collection: $0) }
            case .v2:
                try LingoChatRouter.v2Routes.forEach { try router.register(collection: $0) }
            }
        } catch {
            throw error
        }
    }
}

import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let usersController = UsersController()
    try router.register(collection: usersController)
    
    let chatsController = ChatsController()
    try router.register(collection: chatsController)
    
    #warning("TODO: TESTING ONLY, REMOVE")
    let friendshipsController = FriendshipsController()
    try router.register(collection: friendshipsController)
    
    // MARK: - V2
    let usersControllerV2 = UsersControllerV2()
    try router.register(collection: usersControllerV2)
    
    let chatsControllerV2 = ChatsControllerV2()
    try router.register(collection: chatsControllerV2)
    
    let friendshipsControllerV2 = FriendshipsControllerV2()
    try router.register(collection: friendshipsControllerV2)
    
    let refreshTokenControllerV2 = RefreshTokenControllerV2()
    try router.register(collection: refreshTokenControllerV2)
}

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
}

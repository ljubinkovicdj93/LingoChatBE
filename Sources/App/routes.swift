import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let usersController = UsersController()
    try router.register(collection: usersController)
    
    let languagesController = LanguagesController()
    try router.register(collection: languagesController)
    
    let messagesController = MessagesController()
    try router.register(collection: messagesController)

    let chatsController = ChatsController()
    try router.register(collection: chatsController)
    
    let friendshipsController = FriendshipsController()
    try router.register(collection: friendshipsController)
    
    let userChatsController = UserChatsController()
    try router.register(collection: userChatsController)
}

import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let friendshipsController = FriendshipsController()
    try router.register(collection: friendshipsController)
    
    let groupsController = GroupsController()
    try router.register(collection: groupsController)
    
    let languagesController = LanguagesController()
    try router.register(collection: languagesController)
    
    let messagesController = MessagesController()
    try router.register(collection: messagesController)
    
    let userGroupChatsController = UserGroupChatsController()
    try router.register(collection: userGroupChatsController)
    
    let userGroupsController = UserGroupsController()
    try router.register(collection: userGroupsController)
    
    let usersController = UsersController()
    try router.register(collection: usersController)
}

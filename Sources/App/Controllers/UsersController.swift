// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoutes = router.grouped("api", "users")

        // Creatable
        usersRoutes.post(User.self, use: createHandler)
        
        // Retrievable
        usersRoutes.get(use: getAllHandler)
        usersRoutes.get(User.parameter, use: getHandler)
        usersRoutes.get("first", use: getFirstHandler)
        
        // Updatable
        usersRoutes.put(User.parameter, use: updateHandler)
        
        // Deletable
        usersRoutes.delete(User.parameter, use: deleteHandler)
        
        // Relational endpoints
        // Chat(s)
        usersRoutes.post(User.parameter, "chats", Chat.parameter, use: addChatsHandler)
        usersRoutes.get(User.parameter, "chats", use: getAllChatsHandler)
        usersRoutes.get(User.parameter, "chats-created", use: getChatsCreatedByUserHandler)
        
        // Language(s)
        usersRoutes.post(User.parameter, "languages", Language.parameter, use: addLanguagesHandler)
        usersRoutes.get(User.parameter, "languages", use: getAllLanguagesHandler)

        // Friendship(s)
        usersRoutes.post(User.parameter, "befriend", User.parameter, use: addFriendHandler)
        usersRoutes.get(User.parameter, "friends", use: getFriendsHandler)
        usersRoutes.get(User.parameter, "friendOf", use: getFriendOfHandler)
    }
}

// MARK: - CRUDRepresentable & Queryable
extension UsersController: CRUDRepresentable, Queryable {
    typealias T = User
    
    func updateHandler(_ req: Request) throws -> Future<User> {
        return try flatMap(
            to: User.self,
            req.parameters.next(User.self),
            req.content.decode(User.self)
        ) { user, updatedUser in
            user.firstName = updatedUser.firstName
            user.lastName = updatedUser.lastName
            user.email = updatedUser.email
            user.username = updatedUser.username
            user.password = updatedUser.password
            user.photoUrl = updatedUser.photoUrl
            user.friendCount = updatedUser.friendCount
            
            return user.save(on: req)
        }
    }
}

// MARK: - Chats related methods
extension UsersController {
    func getChatsCreatedByUserHandler(_ req: Request) throws -> Future<[Chat]> {
        return try req.parameters.next(User.self)
            .flatMap(to: [Chat].self) { user in
                try user.chatsCreatedByThisUser.query(on: req).all()
        }
    }
    
    func getAllChatsHandler(_ req: Request) throws -> Future<[Chat]> {
        return try req.parameters.next(User.self)
            .flatMap(to: [Chat].self) { user in
                try user.chats.query(on: req).all()
        }
    }
    
    func addChatsHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(User.self),
                           req.parameters.next(Chat.self)) { user, chat in
                            return user.chats
                                .attach(chat, on: req)
                                .transform(to: .created)
        }
    }
}

// MARK: - Languages related methods
extension UsersController {
    func addLanguagesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(User.self),
                           req.parameters.next(Language.self)) { user, language in
                            return user.languages
                                .attach(language, on: req)
                                .transform(to: .created)
        }
    }
    
    func getAllLanguagesHandler(_ req: Request) throws -> Future<[Language]> {
        return try req.parameters.next(User.self)
            .flatMap(to: [Language].self) { user in
                try user.languages.query(on: req).all()
        }
    }
}

extension UsersController {
    func addFriendHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(User.self),
                           req.parameters.next(User.self)) { user, friend in
                            return try FriendshipPivot(user, friend).save(on: req).transform(to: .created)
        }
    }
    
    func getFriendsHandler(_ req: Request) throws -> Future<[User]> {
        return try req.parameters.next(User.self)
            .flatMap(to: [User].self) { user in
                try user.friends.query(on: req).all()
        }
    }
    
    func getFriendOfHandler(_ req: Request) throws -> Future<[User]> {
        return try req.parameters.next(User.self)
            .flatMap(to: [User].self) { user in
                try user.friendOf.query(on: req).all()
        }
    }
}

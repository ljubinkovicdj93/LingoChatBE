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
        
        // Relations
//        usersRoutes.get(User.parameter, "languages", use: getLanguagesHandler)
//        // Creates a sibling relationship between the user with <USER_ID> and the group with <GROUP_ID>
//        usersRoutes.post(User.parameter, "groups", Group.parameter, use: addGroupsHandler)
//        usersRoutes.get(User.parameter, "groups", use: getGroupsHandler)
//
//        usersRoutes.get(User.parameter, "friends", use: getFriendsHandler)
//        usersRoutes.get(User.parameter, "friendOf", use: getFriendOfHandler)
    }
    
//    func getLanguagesHandler(_ req: Request) throws -> Future<[Language]> {
//        return try req.parameters.next(User.self)
//            .flatMap(to: [Language].self) { user in
//                try user.languages.query(on: req).all()
//        }
//    }
//
//    // Relations
//    func addGroupsHandler(_ req: Request) throws -> Future<HTTPStatus> {
//        return try flatMap(to: HTTPStatus.self,
//                           req.parameters.next(User.self),
//                           req.parameters.next(Group.self)) { user, group in
//                            return user.groups
//                                .attach(group, on: req)
//                                .transform(to: .created)
//        }
//    }
//
//    func getGroupsHandler(_ req: Request) throws -> Future<[Group]> {
//        return try req.parameters.next(User.self)
//            .flatMap(to: [Group].self) { user in
//                try user.groups.query(on: req).all()
//            }
//    }
//
//    func getFriendsHandler(_ req: Request) throws -> Future<[User]> {
//        return try req.parameters.next(User.self)
//            .flatMap(to: [User].self) { user in
//                try user.friends.query(on: req).all()
//        }
//    }
//
//    func getFriendOfHandler(_ req: Request) throws -> Future<[User]> {
//        return try req.parameters.next(User.self)
//            .flatMap(to: [User].self) { user in
//                try user.friendOf.query(on: req).all()
//        }
//    }
}

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

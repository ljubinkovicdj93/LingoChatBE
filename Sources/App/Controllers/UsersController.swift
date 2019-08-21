// Project: LingoChatBE
//
// Created on Thursday, April 04, 2019.
// 

import JWT
import Vapor
import Fluent
import Crypto

enum UserError: Error, LocalizedError {
    case userAlreadyRegistered
    case userDoesntExist(String)
    case wrongPassword
    
    var errorDescription: String? {
        switch self {
        case .userAlreadyRegistered:
            return "The email address has already been registered."
        case .userDoesntExist(let email):
            return "User: '\(email)' doesn't exist in the database."
        case .wrongPassword:
            return "Wrong password inputted."
        }
    }
}

struct UsersController: RouteCollection {
    typealias T = User
    typealias U = User.Public

    func boot(router: Router) throws {
        let usersRoutes = router.grouped("api", "users")

        // Register
        usersRoutes.post(User.self, at: "register", use: registerHandler)
        
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
        
        // Authentication Middleware
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    private func registerHandler(_ req: Request, user: User) throws -> Future<Response> {
        
        do {
            try user.validate()
        } catch (let error) {
            let validationError = error as? ValidationError
            return req.future(req.redirect(to: redirectURL(validationError?.reason)))
        }
        
        return User
                .query(on: req)
                .filter(\.email == user.email)
                .first()
                .flatMap(to: Response.self) { foundUser in
                // Create a new user if no users meeting the email criteria exist.
                guard let _ = foundUser else {
                    user.password = try BCrypt.hash(user.password)
                    
                    return user.save(on: req)
                        .flatMap(to: Token.self, { user -> Future<Token> in
                            let token = try Token.generate(for: user)
                            return token.save(on: req)
                        }).encode(status: HTTPStatus.created, for: req)
                }
                // Such user already exists.
                return req
                        .future(error: BasicValidationError(UserError.userAlreadyRegistered.localizedDescription))
            }
    }
    
    private func redirectURL(_ errorMessage: String?) -> String {
        let redirect: String
        if let message = errorMessage?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            redirect = "/register?message=\(message)"
        } else {
            redirect = "/register?message=Unknown+error"
        }
        return redirect
    }
    
    private func loginHandler(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self) // saves the user's identity in the request's authentication cache, making it easy to retrieve the user object later.
        let token = try Token.generate(for: user)
        return token.save(on: req).encode(status: .ok, for: req)
    }
}

// MARK: - Retrievable
extension UsersController: Retrievable {
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<User.Public> {
        return User.query(on: req)
            .decode(data: User.Public.self)
            .first()
            .unwrap(or: Abort(.notFound))
    }
}

// MARK: - Updatable
extension UsersController: Updatable {
    func updateHandler(_ req: Request) throws -> Future<User.Public> {
        return try flatMap(
            to: User.Public.self,
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
            
            return user.save(on: req).convertToPublic()
        }
    }
}

// MARK: - Deletable
extension UsersController: Deletable {}

// MARK: - Queryable
extension UsersController: Queryable {}

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
    
    func addChatsHandler(_ req: Request) throws -> Future<Response> {
		return try flatMap(to: Response.self,
                           req.parameters.next(User.self),
                           req.parameters.next(Chat.self)) { user, chat in
							
							let pivot = try UserChatPivot(user, chat)
							return pivot
									.save(on: req)
									.withStatus(.created, using: req)
        }
    }
}

// MARK: - Languages related methods
extension UsersController {
    func addLanguagesHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self,
                           req.parameters.next(User.self),
                           req.parameters.next(Language.self)) { user, language in
                            
                            let pivot = try UserLanguagePivot(user, language)
                            
                            return pivot
                                    .save(on: req)
                                    .withStatus(.created, using: req)
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

extension User: Validatable {
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        
        try validations.add(\.email, .email)
        try validations.add(\.firstName, .alphanumeric && .count(2...))
        try validations.add(\.lastName, .alphanumeric && .count(2...))
        try validations.add(\.password, .count(8...))
        try validations.add(\.photoUrl, .url || .nil)
        
        return validations
    }
}

//
//  UsersController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.post(User.self, use: createHandler)
        
        // Authentication related
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        // There is no guard authentication middleware since requireAuthenticated(_:)
        // throws the correct error if a user isn't authenticated.
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
        
        // Protected routes
        #warning("TODO: Find a way to do this in a middleware.")
        // Use https://github.com/skelpo/JWTMiddleware
        //        usersRoute.get("test", use: getTest)
        usersRoute.post(ChatCreateData.self, at: User.parameter, "chats", use: addChatHandler)
        usersRoute.get(User.parameter, "chats", use: getChatsHandler)
        
        // Messaging
        usersRoute.post(MessageCreateData.self, at: User.parameter, "chats", Chat.parameter, use: addMessageToChatHandler)
        usersRoute.get(User.parameter, "chats", Chat.parameter, "messages", use: getUserMessagesHandler)
        
        // Friendship(s)
        usersRoute.post(User.parameter, "friendships", User.parameter, use: addFriendHandler)
        #warning("TODO: REFACTOR THIS!!! STILL NEED A WAY TO DISPLAY PENDING FRIEND REQUESTS FOR A USER WHO HAS SENT A F.R.")
        usersRoute.put(FriendRequestUpdateData.self, at: User.parameter, "friendships", User.parameter, use: updateFriendshipHandler)
        usersRoute.get(User.parameter, "friendships", use: getFriendsHandler)
    }
    
    func getUserMessagesHandler(_ req: Request) throws -> Future<[Message]> {
        // Fetches the token from `Authorization: Bearer <token>` header
        guard req.http.headers.bearerAuthorization != nil else { throw Abort(.unauthorized) }
        
        return try flatMap(to: [Message].self,
                           req.parameters.next(User.self),
                           req.parameters.next(Chat.self)) { _, chat in
                            
                            return try chat.messages.query(on: req).all()
        }
    }
    
    func addMessageToChatHandler(_ req: Request, data: MessageCreateData) throws -> Future<Message> {
        // Fetches the token from `Authorization: Bearer <token>` header
        guard req.http.headers.bearerAuthorization != nil else { throw Abort(.unauthorized) }
        
        do {
            try data.validate()
            
            return try flatMap(to: Message.self,
                               req.parameters.next(User.self),
                               req.parameters.next(Chat.self)) { user, chat in
                                
                                let message = try Message(text: data.text,
                                                          userId: user.requireID(),
                                                          chatId: chat.requireID())
                                return message.save(on: req)
            }
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    func loginHandler(_ req: Request) throws -> JWTResponse {
        // Get the authenticated user from the request. Saves the user's identity in the request's authentication cache, allowing us to retrieve the user object later.
        let user = try req.requireAuthenticated(User.self)
        
        return try createJWT(from: user)
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<JWTResponse> {
        user.password = try BCrypt.hash(user.password)
        return user
            .save(on: req)
            .public
            .map(to: JWTResponse.self) { savedUser in
                return try self.createJWT(from: user)
        }
    }
    
    /// Creates JWT and signs it.
    private func createJWT(from user: User, secret: String = "secret") throws -> JWTResponse {
        let data = try JWT(payload: user.jwtPublic).sign(using: .hs256(key: secret))
        
        guard let jwtString = String(data: data, encoding: .utf8) else { throw Abort(.internalServerError) }
        
        return JWTResponse(token: jwtString)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return try User
            .query(on: req)
            .paginate(on: req)
            .decode(data: User.Public.self)
            .all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).public
    }
    
    // MARK: - Protected routes

    // MARK: - Siblings relationship (many-to-many) related methods.
    func addChatHandler(_ req: Request, data: ChatCreateData) throws -> Future<HTTPStatus> {
        // Fetches the token from `Authorization: Bearer <token>` header
        guard req.http.headers.bearerAuthorization != nil else { throw Abort(.unauthorized) }
        
        do {
            try data.validate()
            
            // Store save operations
            var userSaves: [Future<Void>] = []
            var friendshipPivotUpdates: [Future<FriendshipPivot>] = []
            
            var currentUserId: UUID?
            var currentChatId: UUID?
            
            return try req
                .parameters
                .next(User.self)
                .flatMap { user in
                    guard let id = user.id else { throw Abort(.internalServerError) }
                    currentUserId = id
                    
                    let chat: Chat
                    #warning("TODO: Handle this later")
                    //                if data.users.isEmpty { // If we talk to ourselves...
                    //                    chat = Chat(name: user.public.fullName)
                    //                }
                    if data.users.count == 1 { // If it is an 1-1 chat.
                        chat = Chat(name: data.users[0].fullName)
                    } else { // If it is a group chat.
                        guard let chatName = data.name else { throw BasicValidationError("Must provide `name` when creating a chat with more than 2 users.") }
                        guard !chatName.isEmpty else { throw BasicValidationError("Chat name must NOT be empty!") }
                        
                        chat = Chat(name: chatName)
                    }
                    
                    try userSaves.append(User.addUser(id, to: chat, on: req))
                    return chat.save(on: req)
                }
                .flatMap { (chat: Chat) -> Future<Void> in
                    currentChatId = chat.id
                    
                    for user in data.users {
                        guard let id = user.id else { throw Abort(.internalServerError) }
                        try userSaves.append(User.addUser(id, to: chat, on: req))
                    }
                    
                    // Flattens the array to complete ALL the Fluent operations and transforms the result to an HTTP status code.
//                    return userSaves.flatten(on: req).transform(to: .created)
                    return userSaves.flatten(on: req)
                }
                .flatMap(to: HTTPStatus.self) { _ in
                    return FriendshipPivot
                        .query(on: req)
                        .filter(\.status, .equal, .approved)
                        .all()
                        .flatMap(to: HTTPStatus.self) { (friendships: [FriendshipPivot]) -> Future<HTTPStatus> in
                            guard let currUserID = currentUserId else { throw Abort(.internalServerError) }
                            let chatParticipantIds = data.users.compactMap { $0.id }
                            
                            for friendship in friendships {
                                let friendId: UUID
                                if friendship.senderId == currUserID {
                                    friendId = friendship.receiverId
                                } else if friendship.receiverId == currUserID {
                                    friendId = friendship.senderId
                                } else {
                                    continue
                                }
                                
                                if !chatParticipantIds.contains(friendId) { continue }
                                
                                guard let chatId = currentChatId else { throw Abort(.internalServerError) }
                                
                                friendship.chatId = chatId
                                
                                friendshipPivotUpdates.append(FriendshipPivot.query(on: req).update(friendship))
                            }
                            
                            return friendshipPivotUpdates.flatten(on: req).transform(to: .created)
                        }
            }
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    func getChatsHandler(_ req: Request) throws -> Future<[Chat]> {
        return try req.parameters.next(User.self).flatMap(to: [Chat].self) { user in
            try user.chats.query(on: req).all()
        }
    }
    
    // MARK: - Friend requests
    func updateFriendshipHandler(_ req: Request, data: FriendRequestUpdateData) throws -> Future<Response> {
        do {
            try data.validate()
            
            return try flatMap(to: Response.self,
                               req.parameters.next(User.self),
                               req.parameters.next(User.self)) { user, friend in
                                
                                // This "can't" fail since we have validations set up in place for FriendRequestUpdateData, which always
                                // guarantee that the status can't be anything except:
                                // -1 (declined)
                                //  0 (pending)
                                //  1 (accepted).
                                guard let friendshipStatus = FriendshipPivot.FriendRequestStatus(rawValue: data.status)
                                    else { throw Abort(.internalServerError) }
                                
                                return FriendshipPivot
                                    .query(on: req)
                                    .all()
                                    .flatMap(to: Response.self) {
                                        guard let foundFriendshipRequest = try $0
                                            .filter({
                                                try ($0.senderId == user.requireID() || $0.receiverId == user.requireID())
                                                    || ($0.senderId == friend.requireID() || $0.receiverId == friend.requireID())
                                            })
                                            .first
                                            else { throw Abort(.notFound) }
                                        
                                        foundFriendshipRequest.status = friendshipStatus
                                        
                                        let response = Response(using: req)
                                        
                                        switch foundFriendshipRequest.status {
                                        case .approved:
                                            try response.content.encode(foundFriendshipRequest)
                                            return foundFriendshipRequest.save(on: req).transform(to: response)
                                        case .declined:
                                            response.http.status = .noContent
                                            return foundFriendshipRequest.delete(on: req).transform(to: response)
                                        default:
                                            throw BasicValidationError("Has to have a status of either:\n-1 (declined)\n1 (accepted)")
                                        }
                                }
            }
        } catch {
            throw error
        }
    }
    
    func addFriendHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(User.self),
                           req.parameters.next(User.self)) { user, friend in
                            
                            return FriendshipPivot
                                .query(on: req)
                                .all()
                                .flatMap(to: HTTPStatus.self) {
                                    let foundFriendshipRequest = try $0
                                        .filter({
                                            try ($0.senderId == user.requireID() && $0.receiverId == friend.requireID())
                                             || ($0.senderId == friend.requireID() && $0.receiverId == user.requireID())
                                        })
                                        .first
                                    
                                    guard foundFriendshipRequest == nil else { throw BasicValidationError("Such friendship already exists!") }
                                    
                                    return try FriendshipPivot(user: user,
                                                               friend: friend,
                                                               status: .pending)
                                        .save(on: req)
                                        .transform(to: .created)
                            }
        }
    }
    
    func getFriendsHandler(_ req: Request) throws -> Future<Response> {
        guard let statusTerm = req.query[String.self, at: "status"] else { throw BasicValidationError("status query parameter is mandatory!") }
        guard
            let intStatus = Int(statusTerm),
            intStatus == 0 || intStatus == 1
            else {
                throw BasicValidationError(
                    """
                        Friend request status is invalid. Send one of the following:
                            0 -> Pending (pending friend requests)
                            1 -> Approved (existing friends)
                            2 -> My Pending requests
                    """
                )
        }
        
        let response = Response(using: req)
        
        switch intStatus {
        case 0:
            return try req.parameters.next(User.self).flatMap(to: Response.self) { user in
                guard let id = user.id else { throw Abort(.internalServerError) }
                
                return FriendshipPivot
                    .query(on: req)
                    .filter(\FriendshipPivot.status, .equal, .pending)
                    .filter(\FriendshipPivot.receiverId, .equal, id)
                    .all()
                    .flatMap(to: Response.self) {
                        // Used to fetch friends from chats where the current user is present.
                        var individualUserFetches: [Future<User?>] = []
                        
                        for fp in $0 {
                            let requesterId = fp.senderId
                            let userFetch = User.find(requesterId, on: req)
                            individualUserFetches.append(userFetch)
                        }
                        
                        return individualUserFetches.flatten(on: req).map(to: Response.self) { users in
                            let publicUsers = users.compactMap({ $0?.public })
                            try response.content.encode(publicUsers)
                            
                            return response
//                            return publicUsers
                        }
                }
            }
        case 1:
            return try req.parameters.next(User.self).flatMap(to: Response.self) { user in
                guard let id = user.id else { throw Abort(.internalServerError) }
                
                return FriendshipPivot
                    .query(on: req)
                    .filter(\FriendshipPivot.status, .equal, .approved)
                    .group(.or) { queryBuilder in
                        queryBuilder
                            .filter(\FriendshipPivot.senderId, .equal, id)
                            .filter(\FriendshipPivot.receiverId, .equal, id)
                    }
                    .all()
                    .flatMap(to: Response.self) {
                        // Used to fetch friends from chats where the current user is present.
                        var individualFriendFetches: [Future<FriendDTO>] = []
                        
                        for fp in $0 {
                            let friendId = id == fp.senderId ? fp.receiverId : fp.senderId
                            let userFetch = User.find(friendId, on: req).map(to: FriendDTO.self) { user in
                                return FriendDTO(friend: user?.public, chatId: fp.chatId)
                            }
                            
                            individualFriendFetches.append(userFetch)
                        }
                        
                        return individualFriendFetches.flatten(on: req).map(to: Response.self) { friends in
                            try response.content.encode(friends)
                            
                            return response
                        }
                }
            }
        default:
            throw Abort(.internalServerError)
        }
    }
}

//
//  ChatsController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/18/19.
//

import Foundation
import Vapor
import Crypto
import JWT

struct ChatsControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let chatsRoute = router
            .grouped("api", "v2", "chats")
            .grouped(JWTMiddleware())
        
        chatsRoute.get(use: getUserChatsHandler)
        chatsRoute.get(Chat.parameter, "users", use: getUsersHandler)
        chatsRoute.post(ChatCreateData.self, use: createHandler)
        
        chatsRoute.post(MessageCreateData.self, at: Chat.parameter, use: createMessageHandler)
        chatsRoute.get(Chat.parameter, "messages", use: getChatMessagesHandler)
    }
    
    func createMessageHandler(_ req: Request, data: MessageCreateData) throws -> Future<Message> {
        do {
            try data.validate()
            
            return try req.authorizedUser().flatMap(to: Message.self) { authenticatedUser in
                return try req.parameters.next(Chat.self).flatMap(to: Message.self) { chat in
                    let message = try Message(text: data.text,
                                              userId: authenticatedUser.requireID(),
                                              chatId: chat.requireID())
                    return message.save(on: req)
                }
            }
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    func getChatMessagesHandler(_ req: Request) throws -> Future<[Message]> {
        return try req.authorizedUser().flatMap(to: [Message].self) { authenticatedUser in
            return try req.parameters.next(Chat.self).flatMap(to: [Message].self) { chat in
                return try chat.messages.query(on: req).all()
            }
        }
    }
    
    func createHandler(_ req: Request, data: ChatCreateData) throws -> Future<HTTPStatus> {
        return try req.authorizedUser().flatMap(to: HTTPStatus.self) { authenticatedUser in
            do {
                try data.validate()
                
                // Store save operations
                var userSaves: [Future<Void>] = []
                var friendshipPivotUpdates: [Future<FriendshipPivot>] = []
                
                var currentUserId: UUID?
                var currentChatId: UUID?
                
                guard let id = authenticatedUser.id else { throw Abort(.internalServerError, reason: "User is missing an ID.") }
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
                return chat.save(on: req).flatMap(to: Void.self) { savedChat in
                    currentChatId = chat.id
                    
                    for user in data.users {
                        guard let id = user.id else { throw Abort(.internalServerError) }
                        try userSaves.append(User.addUser(id, to: chat, on: req))
                    }
                    
                    // Flattens the array to complete ALL the Fluent operations and transforms the result to an HTTP status code.
                    // return userSaves.flatten(on: req).transform(to: .created)
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
    }
    
    func getUsersHandler(_ req: Request) throws -> Future<[User.Public]> {
        return try req.authorizedUser().flatMap(to: [User.Public].self) { _ in
            return try req.parameters.next(Chat.self).flatMap(to: [User.Public].self) { chat in
                return try chat.users.query(on: req).decode(data: User.Public.self).all()
            }
        }
    }
    
    func getUserChatsHandler(_ req: Request) throws -> Future<[Chat]> {
        return try req.authorizedUser().flatMap(to: [Chat].self) { authenticatedUser in
            return try authenticatedUser.chats.query(on: req).all()
        }
    }
}

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
    
    /*
         [
             {
                 "id": "A35A5ABE-2B6C-4A8C-B747-81EAC1401AAF",
                 "name": "First chat in the history of LingoChat",
                 "participants": [
             {
                 "id": "59A6983F-6EC6-49DE-A9F2-17253843ED47",
                 "firstName": "Djordje",
                 "lastName": "Ljubinkovic",
                 "username": "djole-lj"
             }
             ],
             "lastMessage": "It was a good day.",
             "createdAt": 1568960152.39124
             }
         ]
     */
    func getUserChatsHandler(_ req: Request) throws -> Future<[ChatDTO]> {
        return try req.authorizedUser().flatMap(to: [ChatDTO].self) { authenticatedUser in
            guard let currentUserId = authenticatedUser.id else { throw Abort(.internalServerError) }
            
            /*
             userId
             chatId
             participantId
             **/
            return UserChatPivot
                .query(on: req)
                .group(.or) { queryBuilder in
                    queryBuilder
                        .filter(\.userId, .equal, currentUserId)
                        .filter(\.participantId, .equal, currentUserId)
            }
            .all()
            .map(to: [ChatDTO].self) {
                // Ensure UserChatPivot table is not empty.
                guard !$0.isEmpty else { return [] }
                let sortedUserChats = $0.sorted { $0.chatId.uuidString < $1.chatId.uuidString }
                
                var prevChatId: Chat.ID = sortedUserChats.first!.chatId
                guard var prevChat: Chat = try Chat.find(prevChatId, on: req).wait() else { throw Abort(.internalServerError, reason: "Chat with \(prevChatId) doesn't exist!") }
                
                var chats2D: [[ChatDTO]] = []
                var participantList: [User.Public] = []
                
                var chatsDtoList: [ChatDTO] = []
                
                for uc in sortedUserChats {
                    let participantId = currentUserId == uc.userId ? uc.participantId : uc.userId
                    
                    if prevChatId == uc.chatId {
                        if let foundUser = try User.find(participantId, on: req).wait() {
                            participantList.append(foundUser.public)
                        }
                    } else {
                        chatsDtoList.append(ChatDTO(chat: prevChat,
                                                    participants: participantList,
                                                    lastMessage: "Ovo je test poruka. Promenicu cim provalim kako da iscupam `lastMessage` iz baze a da je pritom ne unistim koliko su mi dugacki je*eni query-ji :)"))
                        chats2D.append(chatsDtoList)
                        
                        prevChatId = uc.chatId
                        guard let foundChat = try Chat.find(prevChatId, on: req).wait() else { throw Abort(.internalServerError, reason: "Chat with \(prevChatId) doesn't exist!") }
                        prevChat = foundChat
                    }
                }
                
                let allChats = chats2D.flatMap { $0 }
                
                return allChats
            }
        }
    }
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
            if data.participants.count == 1 { // If it is an 1-1 chat.
                chat = Chat(name: data.participants[0].fullName)
            } else { // If it is a group chat.
                guard let chatName = data.name else { throw BasicValidationError("Must provide `name` when creating a chat with more than 2 users.") }
                guard !chatName.isEmpty else { throw BasicValidationError("Chat name must NOT be empty!") }
                
                chat = Chat(name: chatName)
            }
            
            //                try userSaves.append(User.addUser(userId: id, to: chat, participantId: <#UUID#>, on: req))
            return chat.save(on: req).flatMap(to: Void.self) { savedChat in
                currentChatId = chat.id
                
                for user in data.participants {
                    guard let participantId = user.id else { throw Abort(.internalServerError) }
                    try userSaves.append(User.addUser(userId: id, to: chat, participantId: participantId, on: req))
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
                        guard let currUserID = currentUserId else { throw Abort(.internalServerError, reason: "Missing user (chat creator) ID!") }
                        let chatParticipantIds = data.participants.compactMap { $0.id }
                        
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

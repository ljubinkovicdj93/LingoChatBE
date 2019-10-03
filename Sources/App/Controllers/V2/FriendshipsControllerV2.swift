//
//  FriendshipsController.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/19/19.
//

import Vapor
import Fluent

struct FriendshipsControllerV2: RouteCollection {
    func boot(router: Router) throws {
        let friendshipRoutes = router
            .grouped("api", "v2", "friendships")
            .grouped(JWTMiddleware())
        
        friendshipRoutes.post(User.parameter, use: createHandler)
        #warning("TODO: REFACTOR THIS!!! STILL NEED A WAY TO DISPLAY PENDING FRIEND REQUESTS FOR A USER WHO HAS SENT A F.R.")
        friendshipRoutes.put(FriendRequestUpdateData.self, at: User.parameter, use: updateHandler)
        friendshipRoutes.get(use: getAllFriendshipsHandler)
        
        friendshipRoutes.delete(FriendshipPivot.parameter, use: deleteFriendshipHandler)
    }
    
    func createHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.authorizedUser().flatMap(to: HTTPStatus.self) { authenticatedUser in
            return try req.parameters.next(User.self).flatMap(to: HTTPStatus.self) { friend in
                return FriendshipPivot
                    .query(on: req)
                    .all()
                    .flatMap(to: HTTPStatus.self) {
                        let foundFriendshipRequest = try $0
                            .filter({
                                try ($0.senderId == authenticatedUser.requireID() && $0.receiverId == friend.requireID())
                                    || ($0.senderId == friend.requireID() && $0.receiverId == authenticatedUser.requireID())
                            })
                            .first
                        
                        guard foundFriendshipRequest == nil else { throw BasicValidationError("Such friendship already exists!") }
                        
                        return try FriendshipPivot(user: authenticatedUser,
                                                   friend: friend,
                                                   status: .pending)
                            .save(on: req)
                            .transform(to: .created)
                }
            }
        }
    }
    
    #warning("TODO: BUG HERE!!!")
    func updateHandler(_ req: Request, data: FriendRequestUpdateData) throws -> Future<Response> {
        do {
            try data.validate()
            
            return try req.authorizedUser().flatMap(to: Response.self) { authenticatedUser in
                return try req.parameters.next(User.self).flatMap(to: Response.self) { friend in
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
                                    try ($0.senderId == authenticatedUser.requireID() || $0.receiverId == authenticatedUser.requireID())
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
                                response.http.status = .ok
                                return foundFriendshipRequest.delete(on: req).transform(to: response)
                            default:
                                throw BasicValidationError("Has to have a status of either:\n-1 (declined)\n1 (accepted)")
                            }
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    //    [
    //      {
    //        "friend": {
    //          "id": "59A6983F-6EC6-49DE-A9F2-17253843ED47",
    //          "firstName": "Djordje",
    //          "lastName": "Ljubinkovic",
    //          "username": "djole-lj"
    //        },
    //        "status": 0
    //      }
    //    ]
    #warning("TODO: Figure out how to return the above, instead of just users")
//    func getAllFriendshipsHandler(_ req: Request) throws -> Future<[User.Public]> {
    func getAllFriendshipsHandler(_ req: Request) throws -> Future<[FriendDTOV2]> {
        return try req.authorizedUser().flatMap(to: [FriendDTOV2].self) { authenticatedUser in
            guard let id = authenticatedUser.id else { throw Abort(.internalServerError) }
            return FriendshipPivot
                .query(on: req)
                .group(.or) { queryBuilder in
                    queryBuilder
                        .filter(\.senderId, .equal, id)
                        .filter(\.receiverId, .equal, id)
                }
                .all()
                /*
                     senderId | status | receiverId
                     ––––––––––––––––––––––––––––––
                     djole    |    0   | ana
                     stefan   |    1   | djole
                     filip    |    0   | djole
                 
                 
                    0: filip, ana
                    1: stefan
                 */
                .flatMap(to: [FriendDTOV2].self) { friendships in
                    guard !friendships.isEmpty else { return req.future([]) }
                    
                    var friendFetches: [Future<FriendDTOV2>] = []
                    
                    for fr in friendships {
                        let friendId = id == fr.senderId ? fr.receiverId : fr.senderId
                        
                        let friendDtoFetch = User.find(friendId, on: req).map(to: FriendDTOV2.self) { foundUser in
                            guard let existingFriend = foundUser else { throw Abort(.internalServerError, reason: "User with \(friendId) doesn't exist!") }
                            
                            #warning("TODO: CHAT ID MUST EXIST IF THERE IS A CHAT BETWEEN USERS!")
                            return FriendDTOV2(friend: existingFriend.public, status: fr.status.rawValue, chatId: nil)
                        }
                        
                        friendFetches.append(friendDtoFetch)
                    }
                    
                    return friendFetches.flatten(on: req)
                }
        }
        
//        return try req.authorizedUser().flatMap(to: [User.Public].self) { authenticatedUser in
//            return try authenticatedUser
//                .friends
//                .query(on: req)
//                .decode(data: User.Public.self)
//                .all()
//        }
    }
    
    func deleteFriendshipHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(FriendshipPivot.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
}

struct FriendDTOV2: Content {
    let friend: User.Public?
    let status: Int // 0 -> pending, 1 -> friend
    let chatId: Chat.ID?
}

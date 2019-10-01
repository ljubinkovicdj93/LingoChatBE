//
//  AccessDTO.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import Vapor

struct AccessDTO: Content {
    let refreshToken: String
    let accessToken: String
    let expiredAt: Date
}

//
//  RefreshTokenDto.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/24/19.
//

import Vapor

struct RefreshTokenDTO: Content {
    let refreshToken: String
}

//
//  AdminUser.swift
//  App
//
//  Created by Dorde Ljubinkovic on 9/19/19.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

// MARK: - Database seeding (adding an Admin user on app's first boot-up).
struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase
    
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        let password = try? BCrypt.hash("password") // DON'T HARDCODE! Read from an environment variable instead.
        guard let hashedPassword = password else { fatalError("Failed to create the admin user." )}
        
        let user = User(firstName: "Admin",
                        lastName: "User",
                        username: "admin",
                        password: hashedPassword,
                        email: "admin@localhost.com")
        
        return user.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return .done(on: conn)
    }
}


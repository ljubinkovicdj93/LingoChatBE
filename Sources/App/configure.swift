//import FluentSQLite
//import FluentMySQL
import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first as a service to allow the application to interact with PostgreSQL via Fluent.
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Register the configured PostgreSQL database to the database config.
    var databases = DatabasesConfig()
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: "localhost",
        username: "vapor",
        database: "vapor",
        password: "password"
    )
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)

    // Configure migrations, which tell the app which db to use for each model.
    var migrations = MigrationConfig()
    
    // Because we are linking language's userID property to the User table
    // User table MUST be created first!!!
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Language.self, database: .psql)
    migrations.add(model: Message.self, database: .psql)
    migrations.add(model: Chat.self, database: .psql)

    migrations.add(model: UserChatPivot.self, database: .psql)
    migrations.add(model: UserLanguagePivot.self, database: .psql)
    migrations.add(model: FriendshipPivot.self, database: .psql)

    services.register(migrations)
}

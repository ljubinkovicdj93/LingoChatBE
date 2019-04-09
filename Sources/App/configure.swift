import FluentPostgreSQL
import Vapor
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first as a service to allow the application to interact with PostgreSQL via Fluent.
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())
    
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
    
    let databaseConfig: PostgreSQLDatabaseConfig
    if let url = Environment.get("DATABASE_URL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else {
        let hostname =
            Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let databaseName: String
        let databasePort: Int
        if env == .testing {
            databaseName = "vapor-test"
            if let testPort = Environment.get("DATABASE_PORT") {
                databasePort = Int(testPort) ?? 5433
            } else {
                databasePort = 5433
            }
        } else {
            databaseName = "vapor"
            databasePort = 5432
        }
        
        databaseConfig = PostgreSQLDatabaseConfig(
            hostname: hostname,
            port: databasePort,
            username: "vapor",
            database: databaseName,
            password: "password")
    }
    
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)

    // Configure migrations, which tell the app which db to use for each model.
    var migrations = MigrationConfig()
    
    // Because we are linking language's and chat's userID property to the User table
    // User table MUST be created first!!!
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Language.self, database: .psql)
    // Chat must be created after both the User and the Language table,
    // since it cannot be created if either of the above don't exist.
    migrations.add(model: Chat.self, database: .psql)
    migrations.add(model: Message.self, database: .psql)

    migrations.add(model: UserChatPivot.self, database: .psql)
    migrations.add(model: UserLanguagePivot.self, database: .psql)
    migrations.add(model: FriendshipPivot.self, database: .psql)

    services.register(migrations)
}

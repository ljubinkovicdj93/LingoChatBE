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
    migrations.add(model: Friendship.self, database: .psql)
    migrations.add(model: Group.self, database: .psql)
    migrations.add(model: Language.self, database: .psql)
    migrations.add(model: Message.self, database: .psql)
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserGroup.self, database: .psql)
    migrations.add(model: UserGroupChat.self, database: .psql)

    services.register(migrations)
}

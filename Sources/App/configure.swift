//import FluentSQLite
//import FluentMySQL
import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first as a service to allow the application to interact with SQLite via Fluent.
//    try services.register(FluentSQLiteProvider())
//    try services.register(FluentMySQLProvider())
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

    // Configure a SQLite database
//    let sqlite = try SQLiteDatabase(storage: .memory) // .memory -> db resides in memory, it's not persisted to disk and is lost when the app terminates.
//    let persistentSqliteDb = try SQLiteDatabase(storage: .file(path: "db.sqlite"))

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    
//    let databaseConfig = MySQLDatabaseConfig(
//        hostname: "localhost",
//        username: "vapor",
//        password: "password",
//        database: "vapor"
//    )
//    let database = MySQLDatabase(config: databaseConfig)
    
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: "localhost",
        username: "vapor",
        database: "vapor",
        password: "password"
    )
    let database = PostgreSQLDatabase(config: databaseConfig)
    
//    databases.add(database: sqlite, as: .sqlite)
//    databases.add(database: database, as: .mysql)
    databases.add(database: database, as: .psql)
    services.register(databases)

    // Configure migrations, which tells the app which db to use for each model.
    var migrations = MigrationConfig()
//    migrations.add(model: Acronym.self, database: .sqlite)
//    migrations.add(migration: Acronym.self, database: .mysql)
    
//    migrations.add(migration: Acronym.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)

    services.register(migrations)
}

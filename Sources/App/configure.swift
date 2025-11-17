import Vapor
import Fluent
import FluentPostgresDriver

public func configure(_ app: Application) throws {

    let databaseURL = Environment.get("DATABASE_URL")
        ?? "postgres://will_user:secret@localhost:5432/will"

    try app.databases.use(.postgres(url: databaseURL), as: .psql)

    // Bind to all interfaces so real devices on LAN can reach the server.
    app.http.server.configuration.hostname = Environment.get("SERVER_HOSTNAME") ?? "0.0.0.0"
    if let portString = Environment.get("PORT"), let port = Int(portString) {
        app.http.server.configuration.port = port
    }

    app.migrations.add(TargetLogMigration())
    app.migrations.add(TargetLogSeedMigration())
    app.migrations.add(DailyMetricMigration())
    app.migrations.add(YouTubeSessionMigration())

    if app.environment == .development {
        try app.autoMigrate().wait()
    }

    // Ensure errors are always returned as JSON with logging.
    app.middleware.use(JSONErrorMiddleware())

    try routes(app)
}

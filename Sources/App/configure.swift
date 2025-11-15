import Vapor
import Fluent
import FluentPostgresDriver

public func configure(_ app: Application) throws {

    let databaseURL = Environment.get("DATABASE_URL")
        ?? "postgres://will_user:secret@localhost:5432/will"

    try app.databases.use(.postgres(url: databaseURL), as: .psql)

    app.migrations.add(TargetLogMigration())
    app.migrations.add(TargetLogSeedMigration())
    app.migrations.add(DailyMetricMigration())

    if app.environment == .development {
        try app.autoMigrate().wait()
    }

    try routes(app)
}

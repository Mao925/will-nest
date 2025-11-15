import Fluent

struct TargetLogMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TargetLog.schema)
            .id()
            .field("created_at", .datetime, .required)
            .field("purpose", .string, .required)
            .field("duration_seconds", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TargetLog.schema).delete()
    }
}

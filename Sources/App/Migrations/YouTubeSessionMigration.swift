import Fluent

struct YouTubeSessionMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(YouTubeSession.schema)
            .id()
            .field("user_id", .string, .required)
            .field("started_at", .datetime, .required)
            .field("ended_at", .datetime)
            .field("declared_minutes", .int, .required)
            .field("purpose", .string, .required)
            .field("total_duration_seconds", .int)
            .field("visited_urls", .array(of: .string), .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(YouTubeSession.schema).delete()
    }
}

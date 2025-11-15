import Fluent

struct DailyMetricMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(DailyMetric.schema)
            .id()
            .field("date", .string, .required)
            .unique(on: "date")
            .field("will_count", .int, .required)
            .field("block_count", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(DailyMetric.schema).delete()
    }
}

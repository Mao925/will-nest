import Fluent
import Vapor

final class DailyMetric: Model, Content {
    static let schema = "daily_metrics"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "date")
    var date: String

    @Field(key: "will_count")
    var willCount: Int

    @Field(key: "block_count")
    var blockCount: Int

    init() { }

    init(id: UUID? = nil, date: String, willCount: Int, blockCount: Int) {
        self.id = id
        self.date = date
        self.willCount = willCount
        self.blockCount = blockCount
    }

    struct Public: Content {
        let id: UUID
        let date: String
        let willCount: Int
        let blockCount: Int
    }

    func toPublic() throws -> Public {
        guard let id else {
            throw Abort(.internalServerError, reason: "Missing id on DailyMetric")
        }
        return Public(id: id, date: date, willCount: willCount, blockCount: blockCount)
    }
}

import Fluent
import Vapor

final class TargetLog: Model, Content {
    static let schema = "target_logs"

    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "purpose")
    var purpose: String

    @Field(key: "duration_seconds")
    var durationSeconds: Int

    init() { }

    init(id: UUID? = nil, purpose: String, durationSeconds: Int) {
        self.id = id
        self.purpose = purpose
        self.durationSeconds = durationSeconds
    }

    struct Public: Content {
        let id: UUID
        let date: Date
        let purpose: String
        let duration: Int
    }

    func toPublic() throws -> Public {
        guard let id, let createdAt else {
            throw Abort(.internalServerError, reason: "Missing id or createdAt on TargetLog")
        }
        return Public(id: id, date: createdAt, purpose: purpose, duration: durationSeconds)
    }
}

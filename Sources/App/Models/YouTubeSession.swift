import Fluent
import Vapor

final class YouTubeSession: Model, Content {
    static let schema = "youtube_sessions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "user_id")
    var userId: String

    @Field(key: "started_at")
    var startedAt: Date

    @OptionalField(key: "ended_at")
    var endedAt: Date?

    @Field(key: "declared_minutes")
    var declaredMinutes: Int

    @Field(key: "purpose")
    var purpose: String

    @OptionalField(key: "total_duration_seconds")
    var totalDurationSeconds: Int?

    @Field(key: "visited_urls")
    var visitedURLs: [String]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        userId: String,
        startedAt: Date,
        endedAt: Date? = nil,
        declaredMinutes: Int,
        purpose: String,
        totalDurationSeconds: Int? = nil,
        visitedURLs: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.declaredMinutes = declaredMinutes
        self.purpose = purpose
        self.totalDurationSeconds = totalDurationSeconds
        self.visitedURLs = visitedURLs
    }

    struct Public: Content {
        let id: UUID
        let userId: String
        let startTime: Date
        let endTime: Date?
        let purpose: String
        let videoURLs: [String]
        let declaredMinutes: Int
        let totalDuration: Double?
    }

    func toPublic() throws -> Public {
        guard let id else {
            throw Abort(.internalServerError, reason: "Missing id on YouTubeSession")
        }

        return Public(
            id: id,
            userId: userId,
            startTime: startedAt,
            endTime: endedAt,
            purpose: purpose,
            videoURLs: visitedURLs,
            declaredMinutes: declaredMinutes,
            totalDuration: totalDurationSeconds.map(Double.init)
        )
    }

    func toSummaryResponse() throws -> YouTubeSessionSummaryResponse {
        guard let id else {
            throw Abort(.internalServerError, reason: "Missing id on YouTubeSession")
        }

        return YouTubeSessionSummaryResponse(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            declaredMinutes: declaredMinutes,
            purpose: purpose,
            totalDurationSeconds: totalDurationSeconds ?? 0,
            visitedURLs: visitedURLs
        )
    }
}

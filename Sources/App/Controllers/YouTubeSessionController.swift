import Vapor
import Fluent

struct YouTubeSessionStartDTO: Content {
    let userId: String
    let startedAt: Date
    let declaredMinutes: Int
    let purpose: String

    init(userId: String, startedAt: Date, declaredMinutes: Int, purpose: String) {
        self.userId = userId
        self.startedAt = startedAt
        self.declaredMinutes = declaredMinutes
        self.purpose = purpose
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userId = try container.decode(String.self, forKey: .userId)
        let startedAt = try container.decode(Date.self, forKey: .startedAt)
        let declaredMinutes = try container.decodeFlexibleInt(forKey: .declaredMinutes, min: 0)
        let purpose = try container.decode(String.self, forKey: .purpose)
        self.init(userId: userId, startedAt: startedAt, declaredMinutes: declaredMinutes, purpose: purpose)
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case startedAt = "startTime"
        case declaredMinutes
        case purpose
    }
}

struct YouTubeSessionEndDTO: Content {
    let userId: String
    let endedAt: Date
    let totalDurationSeconds: Double
    let visitedURLs: [String]

    init(userId: String, endedAt: Date, totalDurationSeconds: Double, visitedURLs: [String]) {
        self.userId = userId
        self.endedAt = endedAt
        self.totalDurationSeconds = totalDurationSeconds
        self.visitedURLs = visitedURLs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userId = try container.decode(String.self, forKey: .userId)
        let endedAt = try container.decode(Date.self, forKey: .endedAt)
        let totalDurationSeconds = try container.decodeFlexibleDouble(forKey: .totalDurationSeconds, min: 0)
        let visitedURLs = try container.decodeIfPresent([String].self, forKey: .visitedURLs) ?? []
        self.init(userId: userId, endedAt: endedAt, totalDurationSeconds: totalDurationSeconds, visitedURLs: visitedURLs)
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case endedAt = "endTime"
        case totalDurationSeconds = "totalDuration"
        case visitedURLs = "videoURLs"
    }
}

struct YouTubeSessionSummaryResponse: Content {
    let id: UUID
    let startedAt: Date
    let endedAt: Date?
    let declaredMinutes: Int
    let purpose: String
    let totalDurationSeconds: Int
    let visitedURLs: [String]
}

struct YouTubeSessionStartResponse: Content {
    let sessionId: UUID
    let startedAt: Date
}

struct YouTubeSessionEndResponse: Content {
    let sessionId: UUID
    let startedAt: Date
    let endedAt: Date
    let declaredMinutes: Int
    let purpose: String
    let totalDurationSeconds: Int
    let visitedURLs: [String]
}

final class YouTubeSessionController {

    // POST /youtube-sessions/start
    func start(req: Request) -> EventLoopFuture<YouTubeSessionStartResponse> {
        do {
            let dto = try req.content.decode(YouTubeSessionStartDTO.self)

            try Self.validateStart(dto)
            req.logger.info("Start YouTube session requested userId=\(dto.userId) declaredMinutes=\(dto.declaredMinutes) startedAt=\(dto.startedAt)")

            let session = YouTubeSession(
                userId: dto.userId,
                startedAt: dto.startedAt,
                declaredMinutes: dto.declaredMinutes,
                purpose: dto.purpose,
                visitedURLs: []
            )

            return session.save(on: req.db).flatMapThrowing {
                guard let id = session.id else {
                    throw Abort(.internalServerError, reason: "Failed to create session")
                }
                return YouTubeSessionStartResponse(sessionId: id, startedAt: session.startedAt)
            }
        } catch {
            logWithStackTrace(req, error: error, context: "POST /youtube-sessions/start")
            return req.eventLoop.makeFailedFuture(error)
        }
    }

    // PUT /youtube-sessions/:id/end
    func end(req: Request) -> EventLoopFuture<YouTubeSessionEndResponse> {
        do {
            guard let id = req.parameters.get("id", as: UUID.self) else {
                throw Abort(.badRequest, reason: "Invalid session id")
            }

            let dto = try req.content.decode(YouTubeSessionEndDTO.self)
            try Self.validateEnd(dto)
            req.logger.info("End YouTube session requested id=\(id) userId=\(dto.userId) totalDurationSeconds=\(dto.totalDurationSeconds) endedAt=\(dto.endedAt)")

            return YouTubeSession.query(on: req.db)
                .filter(\.$id == id)
                .filter(\.$userId == dto.userId)
                .first()
                .flatMap { session in
                    guard let session else {
                        return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Session not found"))
                    }

                    session.endedAt = dto.endedAt
                    session.totalDurationSeconds = Int(dto.totalDurationSeconds)
                    session.visitedURLs = dto.visitedURLs

                    return session.save(on: req.db).flatMapThrowing { 
                        guard let endedAt = session.endedAt,
                              let totalDurationSeconds = session.totalDurationSeconds else {
                            throw Abort(.internalServerError, reason: "Failed to persist youtube session end")
                        }

                        guard let sessionId = session.id else {
                            throw Abort(.internalServerError, reason: "Missing id on YouTubeSession")
                        }

                        return YouTubeSessionEndResponse(
                            sessionId: sessionId,
                            startedAt: session.startedAt,
                            endedAt: endedAt,
                            declaredMinutes: session.declaredMinutes,
                            purpose: session.purpose,
                            totalDurationSeconds: totalDurationSeconds,
                            visitedURLs: session.visitedURLs
                        )
                    }
                }
        } catch {
            logWithStackTrace(req, error: error, context: "PUT /youtube-sessions/:id/end")
            return req.eventLoop.makeFailedFuture(error)
        }
    }

    // GET /youtube-sessions?userId=...&since=...&limit=...
    func index(req: Request) -> EventLoopFuture<[YouTubeSessionSummaryResponse]> {
        let userId = req.query[String.self, at: "userId"]
            .flatMap { value in
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }

        let rawSince = req.query[String.self, at: "since"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        var sinceDate: Date?
        if let rawSince, !rawSince.isEmpty {
            sinceDate = ISO8601DateFormatter().date(from: rawSince)
            if sinceDate == nil {
                req.logger.warning("Invalid 'since' query parameter received: \(rawSince). Ignoring it.")
            }
        }

        let limitValue = req.query[String.self, at: "limit"].flatMap(Int.init)
        let limit = limitValue.map { min(max($0, 1), 100) } ?? 50

        var builder = YouTubeSession.query(on: req.db)

        if let userId {
            builder = builder.filter(\.$userId == userId)
        }

        if let sinceDate {
            builder = builder.filter(\.$startedAt >= sinceDate)
        }

        return builder
            .sort(\.$startedAt, .descending)
            .limit(limit)
            .all()
            .flatMapThrowing { sessions in
                try sessions.map { session in
                    guard let id = session.id else {
                        throw Abort(.internalServerError, reason: "Missing id on YouTubeSession")
                    }

                    return YouTubeSessionSummaryResponse(
                        id: id,
                        startedAt: session.startedAt,
                        endedAt: session.endedAt,
                        declaredMinutes: session.declaredMinutes,
                        purpose: session.purpose,
                        totalDurationSeconds: session.totalDurationSeconds ?? 0,
                        visitedURLs: session.visitedURLs
                    )
                }
            }
    }

    private static func validateStart(_ dto: YouTubeSessionStartDTO) throws {
        guard !dto.userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "userId must not be empty")
        }
        guard dto.declaredMinutes >= 0 else {
            throw Abort(.badRequest, reason: "declaredMinutes must be zero or positive")
        }
        guard !dto.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "purpose must not be empty")
        }
    }

    private static func validateEnd(_ dto: YouTubeSessionEndDTO) throws {
        guard !dto.userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "userId must not be empty")
        }
        guard dto.totalDurationSeconds >= 0 else {
            throw Abort(.badRequest, reason: "totalDurationSeconds must be non-negative")
        }
    }

}

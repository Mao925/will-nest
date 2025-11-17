import Vapor
import Fluent

struct TargetLogDTO: Content {
    let purpose: String
    let duration: Int?

    init(purpose: String, duration: Int?) {
        self.purpose = purpose
        self.duration = duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let purpose = try container.decode(String.self, forKey: .purpose)
        let duration = try container.decodeIfPresentFlexibleInt(forKey: .duration)
        self.init(purpose: purpose, duration: duration)
    }
}

final class TargetLogController {

    // POST /target-logs
    func create(req: Request) -> EventLoopFuture<TargetLog.Public> {
        do {
            let dto = try req.content.decode(TargetLogDTO.self)

            // purpose のバリデーション
            guard !dto.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw Abort(.badRequest, reason: "purpose must not be empty")
            }
            if let duration = dto.duration, duration < 0 {
                throw Abort(.badRequest, reason: "duration must be zero or positive seconds")
            }

            let log = TargetLog(
                purpose: dto.purpose,
                durationSeconds: dto.duration ?? 0
            )

            return log.save(on: req.db).flatMapThrowing {
                try log.toPublic()
            }
        } catch {
            req.logger.error("POST /target-logs failed: \(error.localizedDescription)")
            return req.eventLoop.makeFailedFuture(error)
        }
    }

    // GET /target-logs
    func index(req: Request) -> EventLoopFuture<[TargetLog.Public]> {
        TargetLog.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()
            .flatMapThrowing { logs in
                try logs.map { try $0.toPublic() }
            }
    }
}

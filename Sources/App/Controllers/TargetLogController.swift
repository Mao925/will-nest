import Vapor
import Fluent

struct TargetLogDTO: Content {
    let purpose: String
    let duration: Int?
}

final class TargetLogController {

    // POST /target-logs
    func create(req: Request) throws -> EventLoopFuture<TargetLog.Public> {
        let dto = try req.content.decode(TargetLogDTO.self)

        // purpose のバリデーション
        guard !dto.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "purpose must not be empty")
        }

        let log = TargetLog(
            purpose: dto.purpose,
            durationSeconds: dto.duration ?? 0
        )

        return log.save(on: req.db).flatMapThrowing {
            try log.toPublic()
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

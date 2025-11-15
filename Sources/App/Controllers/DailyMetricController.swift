import Vapor
import Fluent

struct DailyMetricUpdateDTO: Content {
    let willCount: Int
    let blockCount: Int
}

final class DailyMetricController {

    private let defaultWillCount = 10
    private let defaultBlockCount = 20

    func getToday(req: Request) -> EventLoopFuture<DailyMetric.Public> {
        let today = Self.todayString()
        return fetchOrCreate(date: today, on: req.db)
            .flatMapThrowing { try $0.toPublic() }
    }

    func updateToday(req: Request) throws -> EventLoopFuture<DailyMetric.Public> {
        let dto = try req.content.decode(DailyMetricUpdateDTO.self)

        guard dto.willCount >= 0, dto.blockCount >= 0 else {
            throw Abort(.badRequest, reason: "Counts must be non-negative")
        }

        let today = Self.todayString()

        return fetchOrCreate(date: today, on: req.db).flatMap { metric in
            metric.willCount = dto.willCount
            metric.blockCount = dto.blockCount
            return metric.save(on: req.db).flatMapThrowing {
                try metric.toPublic()
            }
        }
    }

    private func fetchOrCreate(date: String, on db: Database) -> EventLoopFuture<DailyMetric> {
        DailyMetric.query(on: db)
            .filter(\.$date == date)
            .first()
            .flatMap { existing in
                if let existing {
                    return db.eventLoop.makeSucceededFuture(existing)
                }
                let metric = DailyMetric(date: date, willCount: self.defaultWillCount, blockCount: self.defaultBlockCount)
                return metric.save(on: db).map { metric }
            }
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

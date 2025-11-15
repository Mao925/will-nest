import Vapor
import Fluent

struct SessionResetResponse: Content {
    let status: String
    let willCount: Int
    let blockCount: Int
}

final class SessionController {

    private let defaultWillCount = 10
    private let defaultBlockCount = 20

    /// Dev-only API that resets today's counters and log history between app restarts.
    func reset(req: Request) -> EventLoopFuture<Response> {
        let today = Self.todayString()

        let resetDailyMetric = DailyMetric.query(on: req.db)
            .filter(\.$date == today)
            .first()
            .flatMap { existing -> EventLoopFuture<Void> in
                if let metric = existing {
                    metric.willCount = self.defaultWillCount
                    metric.blockCount = self.defaultBlockCount
                    return metric.save(on: req.db).transform(to: ())
                }

                let metric = DailyMetric(
                    date: today,
                    willCount: self.defaultWillCount,
                    blockCount: self.defaultBlockCount
                )
                return metric.save(on: req.db).transform(to: ())
            }

        return resetDailyMetric.flatMap {
            // 2. TargetLog をすべて削除
            TargetLog.query(on: req.db)
                .delete()
                .flatMap {
                    // 3. 開発用のシードデータを再投入したいなら、ここで入れ直す
                    let seeds: [TargetLog] = [
                        .init(purpose: "KINGの資料の調査", durationSeconds: 120),
                        .init(purpose: "マーケ施策のリサーチ", durationSeconds: 300),
                        .init(purpose: "ただのだらだら視聴", durationSeconds: 900),
                        .init(purpose: "UIデザインの研究", durationSeconds: 480),
                        .init(purpose: "競合チャンネル分析", durationSeconds: 600),
                        .init(purpose: "語学学習ビデオ確認", durationSeconds: 180),
                        .init(purpose: "開発Tipsの視聴", durationSeconds: 240),
                        .init(purpose: "ニュースチェック", durationSeconds: 150),
                        .init(purpose: "撮影機材レビュー確認", durationSeconds: 360),
                        .init(purpose: "余暇のエンタメ", durationSeconds: 720)
                    ]

                    let saveFutures = seeds.map { $0.save(on: req.db) }
                    return EventLoopFuture.andAllSucceed(saveFutures, on: req.eventLoop)
                }
                .flatMapThrowing {
                    let payload = SessionResetResponse(
                        status: "ok",
                        willCount: self.defaultWillCount,
                        blockCount: self.defaultBlockCount
                    )
                    var response = Response(status: .ok)
                    try response.content.encode(payload)
                    return response
                }
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

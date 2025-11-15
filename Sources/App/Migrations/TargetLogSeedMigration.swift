import Fluent

struct TargetLogSeedMigration: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
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

        return seeds
            .map { $0.save(on: db) }
            .flatten(on: db.eventLoop)
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        TargetLog.query(on: db).delete()
    }
}

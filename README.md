# will-nest

## Quick start

1. 起動: `docker compose up`
   - `db` サービスで Postgres が立ち上がり、ポート 5432 をホストに公開します。
   - `api` は `DATABASE_URL=postgres://will_user:secret@db:5432/will` を参照し、`ENVIRONMENT=development` のためコンテナ起動時に DB マイグレーションが自動実行されます。
2. 動作確認（別ターミナルから実行例）
   - 目標ログ一覧: `curl -s http://localhost:8080/api/target-logs`
   - 目標ログ作成:
     ```bash
     curl -X POST http://localhost:8080/api/target-logs \
       -H "Content-Type: application/json" \
       -d '{"purpose":"UIデザインの研究","duration":300}'
     ```
   - 今日のメトリクス取得/更新:
     - `curl -s http://localhost:8080/api/daily-metrics/today`
     ```bash
     curl -X PUT http://localhost:8080/api/daily-metrics/today \
       -H "Content-Type: application/json" \
       -d '{"willCount":12,"blockCount":18}'
     ```
   - 開発用リセット（カウンターとログ初期化＋シード投入）:
     - `curl -X POST http://localhost:8080/api/session/reset`
   - YouTube セッション開始/終了/一覧:
     ```bash
     curl -X POST http://localhost:8080/api/youtube-sessions/start \
       -H "Content-Type: application/json" \
       -d '{"userId":"u1","startTime":"2024-07-01T00:00:00Z","declaredMinutes":30,"purpose":"学習"}'

     curl -X PUT http://localhost:8080/api/youtube-sessions/<sessionId>/end \
       -H "Content-Type: application/json" \
       -d '{"userId":"u1","endTime":"2024-07-01T00:10:00Z","totalDuration":600,"videoURLs":["https://youtu.be/abc"]}'

     curl -s "http://localhost:8080/api/youtube-sessions?userId=u1&limit=20"
     ```

フロントエンド側は、API のベース URL がこれまで通り `http://localhost:8080` であれば変更不要です（DB をコンテナ化しただけで API ポートは据え置き）。

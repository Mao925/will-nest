# will-nest

Swift/Vapor 製バックエンド。Docker と docker compose で API と Postgres をまとめて起動できます。

## 必要なもの
- Docker / Docker Desktop（compose v2 が使える環境）

## 起動手順
1. ビルド＆起動  
   `docker compose up --build`  
   - `db`: Postgres 15 をポート 5432 で公開、データはボリューム `postgres-data` に永続化。  
   - `api`: `DATABASE_URL=postgres://will_user:secret@db:5432/will` で DB に接続し、`ENVIRONMENT=development` のため起動時に自動マイグレーションを実行。
2. API ベース URL: `http://localhost:8080`

## 動作確認例（別ターミナル）
- 目標ログ一覧:  
  `curl -s http://localhost:8080/api/target-logs`
- 目標ログ作成:  
  ```bash
  curl -X POST http://localhost:8080/api/target-logs \
    -H "Content-Type: application/json" \
    -d '{"purpose":"UIデザインの研究","duration":300}'
  ```
- 今日のメトリクス取得/更新:  
  `curl -s http://localhost:8080/api/daily-metrics/today`  
  ```bash
  curl -X PUT http://localhost:8080/api/daily-metrics/today \
    -H "Content-Type: application/json" \
    -d '{"willCount":12,"blockCount":18}'
  ```
- 開発用リセット（カウンター/ログ初期化＋シード投入）:  
  `curl -X POST http://localhost:8080/api/session/reset`
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

## よくあるハマりどころ
- API が起動直後に落ちる場合は、DB の起動待ちで接続が拒否されていることがあります。`docker compose up --build api` を再実行するか、`docker compose logs -f api` でエラーメッセージを確認してください。
- ポート競合がある場合は、`docker-compose.yml` の `ports` を変更して再起動してください（例: `8081:8080`）。

フロントエンドは API ベース URL が `http://localhost:8080` であれば変更不要です。

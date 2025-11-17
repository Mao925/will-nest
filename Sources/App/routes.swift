import Vapor

func routes(_ app: Application) throws {
    let targetLogController = TargetLogController()
    let dailyMetricController = DailyMetricController()
    let sessionController = SessionController()
    let youtubeSessionController = YouTubeSessionController()

    let api = app.grouped("api")

    api.get("target-logs", use: targetLogController.index)
    api.post("target-logs", use: targetLogController.create)

    api.get("daily-metrics", "today", use: dailyMetricController.getToday)
    api.put("daily-metrics", "today", use: dailyMetricController.updateToday)

    // Dev-only endpoint to reset session state between app restarts.
    api.post("session", "reset", use: sessionController.reset)

    api.group("youtube-sessions") { routes in
        routes.post("start", use: youtubeSessionController.start)
        routes.put(":id", "end", use: youtubeSessionController.end)
        routes.get(use: youtubeSessionController.index)
    }
}

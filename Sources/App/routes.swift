import Vapor

func routes(_ app: Application) throws {
    let targetLogController = TargetLogController()
    let dailyMetricController = DailyMetricController()
    let sessionController = SessionController()

    app.get("target-logs", use: targetLogController.index)
    app.post("target-logs", use: targetLogController.create)

    app.get("daily-metrics", "today", use: dailyMetricController.getToday)
    app.put("daily-metrics", "today", use: dailyMetricController.updateToday)

    // Dev-only endpoint to reset session state between app restarts.
    app.post("session", "reset", use: sessionController.reset)
}

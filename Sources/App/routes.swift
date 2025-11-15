import Vapor

func routes(_ app: Application) throws {
    let controller = TargetLogController()

    app.get("target-logs", use: controller.index)
    app.post("target-logs", use: controller.create)
}

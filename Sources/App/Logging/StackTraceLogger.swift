import Vapor

/// Logs an error with a stack trace for easier debugging when running on device.
func logWithStackTrace(_ req: Request, error: Error, context: String) {
    let stack = Thread.callStackSymbols.joined(separator: "\n")
    req.logger.error("\(context) error: \(error)\n\(stack)")
}

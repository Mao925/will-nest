import Vapor

struct JSONErrorResponse: Content {
    let error: String
}

/// Returns errors as JSON and logs stack traces for easier debugging.
struct JSONErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).flatMapError { error in
            logWithStackTrace(request, error: error, context: "Unhandled error")

            let status: HTTPStatus
            let reason: String

            if let abortError = error as? AbortError {
                status = abortError.status
                reason = abortError.reason
            } else {
                status = .internalServerError
                reason = "Something went wrong"
            }

            do {
                let response = Response(status: status)
                try response.content.encode(JSONErrorResponse(error: reason))
                return request.eventLoop.makeSucceededFuture(response)
            } catch {
                request.logger.error("Failed to encode error response: \(error)")
                return request.eventLoop.makeSucceededFuture(Response(status: status))
            }
        }
    }
}

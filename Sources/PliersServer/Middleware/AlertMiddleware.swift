import PliersCommon
import Vapor

final class AlertMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch let error as AbortError where error.status.code < 400 {
			throw error
		} catch {
			request.logger.report(error: error)
			return try await request.render { View.Page.ErrorPage(error: error) }
		}
	}
}

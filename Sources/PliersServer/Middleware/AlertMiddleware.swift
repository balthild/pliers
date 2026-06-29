import PliersCommon
import Vapor

final class AlertMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch {
			return try await request.render { UI.Page.Error(error: error) }
		}
	}
}

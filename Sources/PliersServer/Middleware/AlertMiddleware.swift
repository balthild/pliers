import PliersCommon
import Vapor

final class AlertMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch {
			let response = request.render { UI.Page.Error(error: error) }
			return try await response.encodeResponse(for: request)
		}
	}
}

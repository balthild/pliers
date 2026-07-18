import PliersCommon
import Vapor

final class AlertMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch let error as AbortError where error.status.code < 400 {
			throw error
		} catch {
			let status: HTTPStatus
			switch error {
			case let error as AbortError: status = error.status
			case is AlertError: status = .badRequest
			default: status = .internalServerError
			}

			if request.clientAcceptsJson {
				throw Abort(status, reason: error.localizedDescription)
			} else {
				request.logger.report(error: error)
				return try await request.render(status: status) {
					View.Page.ErrorPage(error: error)
				}
			}
		}
	}
}

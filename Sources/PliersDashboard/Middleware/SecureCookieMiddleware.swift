import Vapor

/// Marks the session cookie `Secure` for HTTPS requests. Vapor's cookie factory cannot see the
/// request, so it is applied here.
struct SecureCookieMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		let response = try await next.respond(to: request)

		guard request.url.scheme == "https" else {
			return response
		}

		let name = request.application.sessions.configuration.cookieName
		guard var cookie = response.cookies[name] else {
			return response
		}

		cookie.isSecure = true
		response.cookies[name] = cookie

		return response
	}
}

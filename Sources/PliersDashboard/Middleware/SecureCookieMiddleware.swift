import Vapor

/// Marks the session cookie `Secure` when the client connected over HTTPS.
///
/// Vapor's cookie factory cannot see the request, so the flag is applied here instead. The
/// cookie stays usable over plain HTTP (local development) but is only sent back over TLS once
/// the panel is reached through a TLS-terminating proxy.
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

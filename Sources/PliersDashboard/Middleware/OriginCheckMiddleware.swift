import PliersCommon
import Vapor

/// Rejects state-changing requests that do not originate from the panel's own origin.
///
/// Without an anti-CSRF token this check is the panel's primary CSRF defense: a cross-site
/// form submission carries the attacker's origin, which will not match the panel's host.
/// `GET`/`HEAD` are ignored because they must not change state.
struct OriginCheckMiddleware: AsyncMiddleware {
	private static let methods: [HTTPMethod] = [.POST, .PUT, .PATCH, .DELETE]

	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard Self.methods.contains(request.method) else {
			return try await next.respond(to: request)
		}

		let allowed = Origin.isSameOrigin(
			origin: request.headers.first(name: .origin),
			referer: request.headers.first(name: .referer),
			host: request.headers.first(name: .host) ?? "",
			scheme: request.url.scheme ?? "http",
			allowlist: request.config.httpOrigins,
		)

		guard allowed else {
			throw Abort(.forbidden, reason: "cross-site request rejected")
		}

		return try await next.respond(to: request)
	}
}

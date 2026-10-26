import PliersCommon
import Vapor

/// Rewrites `request.url.scheme` from `X-Forwarded-Proto`, only when the peer is a configured
/// trusted proxy (a direct client must not be able to forge its scheme). Pliers listens in plain
/// HTTP behind a TLS-terminating proxy, so `request.url.scheme` would otherwise be `http` for an
/// HTTPS client.
struct TrustedProxiesMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		if let peer = request.remoteAddress?.ipAddress,
			request.config.trustedProxies.contains(where: { peer.isInCIDR($0) }),
			let scheme = Self.forwardedScheme(request.headers.first(name: .xForwardedProto))
		{
			request.url.scheme = scheme
		}

		return try await next.respond(to: request)
	}

	/// Extracts the client scheme from a possibly comma-separated forwarding header.
	private static func forwardedScheme(_ value: String?) -> String? {
		guard let first = value?.split(separator: ",").first else {
			return nil
		}

		let scheme = first.trimmed.lowercased()
		return scheme.isEmpty ? nil : scheme
	}
}

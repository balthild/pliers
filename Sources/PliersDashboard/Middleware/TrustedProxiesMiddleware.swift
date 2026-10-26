import PliersCommon
import Vapor

/// Rewrites the client-facing scheme from a trusted reverse proxy's forwarding header.
///
/// Pliers listens in plain HTTP behind a TLS-terminating proxy, so `request.url.scheme` is
/// `http` even for an HTTPS client; `X-Forwarded-Proto` restores the real scheme for everything
/// downstream (secure cookies, the origin check, WebAuthn origins). The header is applied only
/// when the immediate peer is a configured trusted proxy, so a client that reaches the panel
/// directly cannot forge its scheme.
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

import Foundation

/// Same-origin validation for state-changing requests.
///
/// Pliers carries no anti-CSRF token, so `Origin`/`Referer` validation is the primary
/// defense against cross-site request forgery: a browser attaches the attacker's origin to
/// a cross-site submission, which will not match the panel's own origin.
public enum Origin {
	/// Whether a request's `Origin`/`Referer` identifies the same origin as the request target.
	///
	/// `Origin` takes precedence and `Referer` is only a fallback, because browsers omit
	/// `Referer` more often than `Origin`. A request that carries neither, or a literal `null`
	/// origin (an opaque origin such as a sandboxed frame), is rejected so the check fails
	/// closed. `allowlist` accepts additional origins verbatim, for deployments where a reverse
	/// proxy rewrites the `Host` header.
	public static func isSameOrigin(
		origin: String?,
		referer: String?,
		host: String,
		scheme: String,
		allowlist: [String] = [],
	) -> Bool {
		let source = [origin, referer]
			.compactMap { $0?.trimmed }
			.first { !$0.isEmpty && $0.lowercased() != "null" }

		guard let source, let sourceOrigin = normalize(source) else {
			return false
		}

		if allowlist.contains(where: { normalize($0) == sourceOrigin }) {
			return true
		}

		guard let targetOrigin = normalize("\(scheme)://\(host)") else {
			return false
		}

		return sourceOrigin == targetOrigin
	}

	/// Reduces a URL to a comparable `scheme://host:port` origin, or `nil` when it is not a
	/// plain `http`/`https` origin. Path, query, fragment, and userinfo are discarded, and
	/// whitespace or control characters are rejected so the URL parser cannot reinterpret a
	/// malformed value as a valid origin.
	private static func normalize(_ value: String) -> String? {
		let value = value.trimmed
		guard !value.isEmpty, value.lowercased() != "null" else {
			return nil
		}

		guard !value.unicodeScalars.contains(where: { $0.value < 0x21 || $0.value == 0x7f }) else {
			return nil
		}

		guard
			let url = URL(string: value),
			let scheme = url.scheme?.lowercased(),
			scheme == "http" || scheme == "https",
			let host = url.host?.lowercased(),
			!host.isEmpty,
			url.user == nil,
			url.password == nil
		else {
			return nil
		}

		let port = url.port ?? (scheme == "https" ? 443 : 80)
		return "\(scheme)://\(host):\(port)"
	}
}

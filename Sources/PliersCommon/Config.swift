import Foundation
import Path

public struct Config: Sendable {
	public let port: UInt16
	public let state: Path

	/// Extra origins the CSRF check accepts besides the request's own host, for a proxy that
	/// rewrites `Host`.
	public let httpOrigins: [String]

	/// Peers whose `X-Forwarded-Proto` the panel trusts, as IPs or CIDR blocks. Headers from any
	/// other peer are ignored. Defaults to loopback.
	public let trustedProxies: [String]

	/// Proxies trusted when none are configured: the local host.
	public static let defaultTrustedProxies = ["127.0.0.1/8", "::1/128"]

	public init(
		port: UInt16,
		state: Path,
		httpOrigins: [String] = [],
		trustedProxies: [String] = Config.defaultTrustedProxies,
	) throws {
		self.port = port
		self.state = state
		self.httpOrigins = httpOrigins
		self.trustedProxies = trustedProxies

		guard port >= 1024 else {
			throw RuntimeError("invalid port")
		}
	}

	public static func load() throws -> Self {
		let path = C.conf / "pliers.conf"
		let text = try Result { try String(contentsOf: path, encoding: .utf8) }
			.expect("failed to read config file \(path.string)")

		let entries = try Result { try parse(text) }
			.expect("failed to parse config file \(path.string)")

		let port: String = try entries["port"].expect("missing option 'port'")
		let state: String = try entries["state"].expect("missing option 'state'")

		return try Self(
			port: UInt16(port).expect("invalid port"),
			state: Path(state).expect("invalid state path"),
			httpOrigins: Self.parseHTTPOrigins(entries["http_origins"]),
			trustedProxies: Self.parseTrustedProxies(entries["trusted_proxies"]),
		)
	}

	/// Parses the comma-separated `http_origins`. Blank entries are dropped.
	public static func parseHTTPOrigins(_ value: String?) -> [String] {
		return Self.parseList(value)
	}

	/// Parses the comma-separated `trusted_proxies`, defaulting to loopback when empty.
	public static func parseTrustedProxies(_ value: String?) -> [String] {
		let list = Self.parseList(value)
		return list.isEmpty ? Self.defaultTrustedProxies : list
	}

	private static func parseList(_ value: String?) -> [String] {
		return (value ?? "")
			.split(separator: ",")
			.map { $0.trimmed }
			.filter { !$0.isEmpty }
	}

	private static func parse(_ text: String) throws -> [String: String] {
		var entries = [String: String]()

		for line in text.split(separator: "\n") {
			let line = line.trimmed
			guard !line.isEmpty && !line.hasPrefix("#") else { continue }

			guard let index = line.firstIndex(of: "=") else {
				throw RuntimeError("invalid syntax at line \(line)")
			}

			let key = line[..<index].trimmed
			let value = line[line.index(after: index)...].trimmed

			if entries[key] != nil {
				throw RuntimeError("duplicate option '\(key)'")
			}

			entries[key] = value
		}

		return entries
	}
}

import Foundation
import Path

public struct Config: Sendable {
	public let port: UInt16
	public let state: Path

	/// Extra origins the CSRF origin check accepts besides the request's own host, for panels
	/// behind a proxy that rewrites the `Host` header. Each entry is a `scheme://host[:port]` origin.
	public let httpOrigins: [String]

	public init(port: UInt16, state: Path, httpOrigins: [String] = []) throws {
		self.port = port
		self.state = state
		self.httpOrigins = httpOrigins

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
		)
	}

	/// Parses the comma-separated `http_origins` option, tolerating surrounding whitespace
	/// and empty entries so a malformed value can only ever allow fewer origins, never more.
	public static func parseHTTPOrigins(_ value: String?) -> [String] {
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

import Foundation

public struct Config: Sendable {
	public let port: UInt16
	public let state: URL

	public static func load() throws -> Self {
		let path = Constants.configDir.appending(path: "pliers.conf")
		let text = try Result { try String(contentsOf: path, encoding: .utf8) }
			.expect("failed to read config file \(path.path)")

		let entries = try Result { try parse(text) }
			.expect("failed to parse config file \(path.path)")

		let port: String = try entries["port"].expect("missing option 'port'")
		let state: String = try entries["state"].expect("missing option 'state'")

		let config = try Self(
			port: UInt16(port).expect("invalid port"),
			state: URL(filePath: state, directoryHint: .isDirectory),
		)

		guard config.port >= 1024 else {
			throw RuntimeError("invalid port")
		}

		return config
	}

	private static func parse(_ text: String) throws -> [String: String] {
		var entries = [String: String]()

		for line in text.split(separator: "\n") {
			let line = line.trimmingCharacters(in: .whitespaces)
			guard !line.isEmpty, !line.hasPrefix("#") else { continue }

			guard let index = line.firstIndex(of: "=") else {
				throw RuntimeError("invalid syntax at line \(line)")
			}

			let key = line[..<index].trimmingCharacters(in: .whitespaces)
			let value = line[line.index(after: index)...].trimmingCharacters(in: .whitespaces)

			if entries[key] != nil {
				throw RuntimeError("duplicate option '\(key)'")
			}

			entries[key] = value
		}

		return entries
	}
}

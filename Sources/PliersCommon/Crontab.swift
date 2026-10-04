public enum Crontab {
	public static let startMarker = "# pliers-start"
	public static let endMarker = "# pliers-end"

	public struct Entry: Sendable, Equatable {
		public let expr: String
		public let command: String

		public init(expr: String, command: String) {
			self.expr = expr
			self.command = command
		}

		public var line: String {
			return "\(self.expr) \(Crontab.normalize(command: self.command))"
		}
	}

	public static func normalize(command: String) -> String {
		let replaced =
			command
			.replacingOccurrences(of: "\r\n", with: " ")
			.replacingOccurrences(of: "\n", with: " ")
			.replacingOccurrences(of: "\r", with: " ")
		return replaced.trimmed
	}

	/// If `existing` already contains a `# pliers-start` .. `# pliers-end` block,
	/// the block is replaced in place; otherwise the block is appended to the end.
	public static func merge(into existing: String, entries: [Entry]) -> String {
		let block = [startMarker] + entries.map(\.line) + [endMarker]

		var lines = existing.components(separatedBy: "\n")
		while lines.last == "" {
			lines.removeLast()
		}

		if let start = lines.firstIndex(where: { $0.trimmed == startMarker }),
			let end = lines[start...].firstIndex(where: { $0.trimmed == endMarker })
		{
			lines.replaceSubrange(start...end, with: block)
		} else {
			if !lines.isEmpty {
				lines.append("")
			}
			lines.append(contentsOf: block)
		}

		return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
	}
}

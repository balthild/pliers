@propertyWrapper
public struct Lines: Codable, Sendable {
	public let wrappedValue: [String]

	public init(_ wrappedValue: [String]?) {
		self.wrappedValue = wrappedValue ?? []
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)

		self.wrappedValue =
			value
			.components(separatedBy: .newlines)
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue.joined(separator: "\n"))
	}
}

@propertyWrapper
public struct Lines: Codable, Sendable {
	public let wrappedValue: [String]

	public init(wrappedValue: [String] = []) {
		self.wrappedValue = wrappedValue
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)

		self.wrappedValue =
			value
			.components(separatedBy: .newlines)
			.map { $0.trimmed }
			.filter { !$0.isEmpty }
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue.joined(separator: "\n"))
	}
}

extension Lines: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: String...) {
		self.init(wrappedValue: elements)
	}
}

extension KeyedDecodingContainer {
	public func decode(_ type: Lines.Type, forKey key: Key) throws -> Lines {
		return try self.decodeIfPresent(type, forKey: key) ?? Lines()
	}
}

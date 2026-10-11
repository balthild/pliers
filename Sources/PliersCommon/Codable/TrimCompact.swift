@propertyWrapper
public struct TrimCompact: Codable, Sendable {
	public var wrappedValue: [String]

	public init(wrappedValue: [String] = []) {
		self.wrappedValue = wrappedValue
	}

	public init(from decoder: Decoder) throws {
		self.wrappedValue = try [String](from: decoder)
			.map(\.trimmed)
			.filter { !$0.isEmpty }
	}

	public func encode(to encoder: Encoder) throws {
		try self.wrappedValue.encode(to: encoder)
	}
}

extension TrimCompact: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: String...) {
		self.init(wrappedValue: elements)
	}
}

extension KeyedDecodingContainer {
	public func decode(_ type: TrimCompact.Type, forKey key: Key) throws -> TrimCompact {
		try self.decodeIfPresent(type, forKey: key) ?? TrimCompact()
	}
}

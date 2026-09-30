@propertyWrapper
public struct AllowEmpty<T>: Codable
where T: Codable {
	public var wrappedValue: T?

	public init(wrappedValue: T? = nil) {
		self.wrappedValue = wrappedValue
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		if let value = try? container.decode(String.self), value.isEmpty {
			self.wrappedValue = nil
		} else {
			self.wrappedValue = try container.decode(T.self)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue)
	}
}

extension AllowEmpty: ExpressibleByNilLiteral {
	public init(nilLiteral: ()) {
		self.init()
	}
}

extension AllowEmpty: Sendable
where T: Sendable {}

extension KeyedDecodingContainer {
	public func decode<T>(_ type: AllowEmpty<T>.Type, forKey key: Key) throws -> AllowEmpty<T>
	where T: Codable {
		return try decodeIfPresent(type, forKey: key) ?? AllowEmpty()
	}
}

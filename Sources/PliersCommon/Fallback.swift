extension Decodable {
	public typealias Fallback<T> = DefaultFallback<T>
	where T: Sendable & Codable & Default
}

@propertyWrapper
public struct DefaultFallback<T>: Sendable, Codable
where T: Sendable & Codable & Default {
	public let wrappedValue: T

	public init() {
		self.wrappedValue = T.defaultValue
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let value = try? container.decode(T.self) {
			self.wrappedValue = value
		} else {
			self.wrappedValue = T.defaultValue
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue)
	}
}

extension KeyedDecodingContainer {
	func decode<T>(_ type: DefaultFallback<T>.Type, forKey key: Key) throws -> DefaultFallback<T>
	where T: Sendable & Codable & Default {
		return try decodeIfPresent(type, forKey: key) ?? DefaultFallback()
	}
}
